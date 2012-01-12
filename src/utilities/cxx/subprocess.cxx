/**
 * @file subprocess.cxx
 * @brief Definition of module used to execute subprocesses.
 *
 * Copyright (c) 2011 University of Pennsylvania. All rights reserved.
 * See https://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
 *
 * Contact: SBIA Group <sbia-software at uphs.upenn.edu>
 */


#include <sbia/basis/config.h> // WINDOWS, UNIX,... macros

#include <iostream>

#include <cstdlib>
#include <cassert>   // assert
#include <cstring>   // strlen
#include <algorithm> // for_each

#if UNIX
#  include <sys/wait.h>
#  include <signal.h>
#endif

#include <sbia/basis/except.h>
#include <sbia/basis/subprocess.h>


using namespace std;


namespace sbia
{

namespace basis
{


// ===========================================================================
// helpers
// ===========================================================================

// ---------------------------------------------------------------------------
// Attention: Order matters! First, escaped backslashes are converted to
//            the unused ASCII character 255 and finally these characters are
//            replaced by single backslashes.
static const char* olds[] = {"\\\\", "\\\"", "\xFF"};
static const char* news[] = {"\xFF", "\"",   "\\"};

/**
 * @brief Function object used to convert special characters in command-line
 *        given as single string.
 */
struct ConvertSpecialChars
{
    void operator ()(string& str)
    {
        string::size_type i;
        for (unsigned int n = 0; n < 3; n++) {
            while ((i = str.find(olds[n])) != string::npos) {
                str.replace(i, strlen(olds[n]), news[n]);
            }
        }
    }
}; // struct ConvertSpecialChars

// ---------------------------------------------------------------------------
Subprocess::CommandLine Subprocess::split(const string& cmd)
{
    const char whitespace[] = " \f\n\r\t\v";

    CommandLine args;
    string::size_type j;
    string::size_type k;
    unsigned int      n;

    for (string::size_type i = 0; i < cmd.size(); i++) {
        if (cmd[i] == '\"') {
            j = i;
            do {
                j = cmd.find('\"', ++j);
                if (j == string::npos) break;
                // count number of backslashes to determine whether this
                // double quote is escaped or not
                k = j;
                n = 0;
                // Note: There is at least the leading double quote (").
                //       Hence, k will always be > 0 here.
                while (cmd[--k] == '\\') n++;
                // continue while found double quote is escaped
            } while (n % 2);
            // if trailing double quote is missing, consider leading
            // double quote to be part of argument which extends to the
            // end of the entire string
            if (j == string::npos) {
                args.push_back(cmd.substr(i));
                break;
            } else {
                args.push_back(cmd.substr(i + 1, j - i - 1));
                i = j;
            }
        } else if (isspace(cmd[i])) {
            j = cmd.find_first_not_of(whitespace, i);
            i = j - 1;
        } else {
            j = i;
            do {
                j = cmd.find_first_of(whitespace, ++j);
                if (j == string::npos) break;
                // count number of backslashes to determine whether this
                // whitespace character is escaped or not
                k = j;
                n = 0;
                if (cmd[j] == ' ') {
                    // Note: The previous else block handles whitespaces
                    //       in between arguments including leading whitespaces.
                    //       Hence, k will always be > 0 here.
                    while (cmd[--k] == '\\') n++;
                }
                // continue while found whitespace is escaped
            } while (n % 2);
            if (j == string::npos) {
                args.push_back(cmd.substr(i));
                break;
            } else {
                args.push_back(cmd.substr(i, j - i));
                i = j - 1;
            }
        }
    }

    for_each(args.begin(), args.end(), ConvertSpecialChars());

    return args;
}

// ---------------------------------------------------------------------------
string Subprocess::tostring(const CommandLine& args)
{
    const char whitespace[] = " \f\n\r\t\v";

    string cmd;
    string arg;
    string::size_type j;

    for (CommandLine::const_iterator i = args.begin(); i != args.end(); ++i) {
        if (!cmd.empty()) cmd.push_back(' ');
        if (i->find_first_of(whitespace) != string::npos) {
            arg = *i;
            // escape backslashes (\) and double quotes (")
            j = arg.find_first_of("\\\"");
            while (j != string::npos) {
                arg.insert(j, 1, '\\');
                j = arg.find_first_of("\\\"", j + 2);
            }
            // surround argument by double quotes
            cmd.push_back('\"');
            cmd.append(arg);
            cmd.push_back('\"');
        } else {
            cmd.append(*i);
        }
    }
    return cmd;
}

// ===========================================================================
// construction / destruction
// ===========================================================================

// ---------------------------------------------------------------------------
Subprocess::Subprocess ()
{
#if WINDOWS
    ZeroMemory(&_info, sizeof(_info));
    _stdin = INVALID_HANDLE_VALUE;
    _stdout = INVALID_HANDLE_VALUE;
    _stderr = INVALID_HANDLE_VALUE;
#else
    _info.pid = -1;
    _stdin = -1;
    _stdout = -1;
    _stderr = -1;
#endif
    _status = -1;
}

// ---------------------------------------------------------------------------
Subprocess::~Subprocess ()
{
#if WINDOWS
    if (_info.hProcess) {
        terminate();
        if (_stdin) CloseHandle(_stdin);
        if (_stdout) CloseHandle(_stdout);
        if (_stderr) CloseHandle(_stderr);
        CloseHandle(_info.hProcess);
        CloseHandle(_info.hThread);
    }
#else
    if (_info.pid != 0) kill();
    if (_stdin  != -1) close(_stdin);
    if (_stdout != -1) close(_stdout);
    if (_stderr != -1) close(_stderr);
#endif
}

// ===========================================================================
// process control
// ===========================================================================

// ---------------------------------------------------------------------------
bool Subprocess::popen(const CommandLine& args,
                       const RedirectMode rm_in,
                       const RedirectMode rm_out,
                       const RedirectMode rm_err,
                       const Environment* env)
{
#if WINDOWS
    if (_info.hProcess != 0 && !poll()) {
        cerr << "Subprocess::popen(): Previously opened process not terminated yet!" << endl;
        return false;
    }

    ZeroMemory(&_info, sizeof(_info));
    if (_stdin)  CloseHandle(_stdin);
    if (_stdout) CloseHandle(_stdout);
    if (_stderr) CloseHandle(_stderr);
    _stdin  = INVALID_HANDLE_VALUE;
    _stdout = INVALID_HANDLE_VALUE;
    _stderr = INVALID_HANDLE_VALUE;
    _status = -1;

    SECURITY_ATTRIBUTES saAttr; 
    HANDLE hStdIn[2]  = {INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE}; // read, write
    HANDLE hStdOut[2] = {INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE};
    HANDLE hStdErr[2] = {INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE};
 
    // set the bInheritHandle flag so pipe handles are inherited
    saAttr.nLength              = sizeof(SECURITY_ATTRIBUTES); 
    saAttr.bInheritHandle       = TRUE; 
    saAttr.lpSecurityDescriptor = NULL;

    // create pipes for standard input/output
    if (rm_in == RM_PIPE && CreatePipe(&hStdIn[0], &hStdIn[1], &saAttr, 0) == 0) {
        cerr << "Subprocess::popen(): Failed to create pipe!" << endl;
        return false;
    }

    if (rm_out == RM_PIPE && CreatePipe(&hStdOut[0], &hStdOut[1], &saAttr, 0) == 0) {
        CloseHandle(hStdIn[0]);
        CloseHandle(hStdIn[1]);
        cerr << "Subprocess::popen(): Failed to create pipe!" << endl;
        return false;
    }

    if (rm_err == RM_PIPE && CreatePipe(&hStdErr[0], &hStdErr[1], &saAttr, 0) == 0) {
        CloseHandle(hStdIn[0]);
        CloseHandle(hStdIn[1]);
        CloseHandle(hStdOut[0]);
        CloseHandle(hStdOut[1]);
        cerr << "Subprocess::popen(): Failed to create pipe!" << endl;
        return false;
    }

    // ensure that handles not required by subprocess are not inherited
    if ((hStdIn[1] != INVALID_HANDLE_VALUE && !SetHandleInformation(hStdIn[1], HANDLE_FLAG_INHERIT, 0)) ||
            (hStdOut[0] != INVALID_HANDLE_VALUE && !SetHandleInformation(hStdOut[0], HANDLE_FLAG_INHERIT, 0)) ||
            (hStdErr[0] != INVALID_HANDLE_VALUE && !SetHandleInformation(hStdErr[0], HANDLE_FLAG_INHERIT, 0))) {
        CloseHandle(hStdIn[0]);
        CloseHandle(hStdIn[1]);
        CloseHandle(hStdOut[0]);
        CloseHandle(hStdOut[1]);
        CloseHandle(hStdErr[0]);
        CloseHandle(hStdErr[1]);
        cerr << "Subprocess::popen(): Failed to create pipe!" << endl;
        return false;
    }

    // create subprocess
    STARTUPINFO siStartInfo;
    ZeroMemory(&siStartInfo, sizeof(STARTUPINFO));
    siStartInfo.cb          = sizeof(STARTUPINFO); 
    siStartInfo.hStdError   = hStdErr[1];
    siStartInfo.hStdOutput  = hStdOut[1];
    siStartInfo.hStdInput   = hStdIn[0];
    siStartInfo.dwFlags    |= STARTF_USESTDHANDLES;

    string cmd = tostring(args);

    LPTSTR szCmdline = NULL;
#ifdef UNICODE
    int n = MultiByteToWideChar(CP_UTF8, 0, cmd.c_str(), -1, NULL, 0);
    szCmdline = new TCHAR[n];
    if (szCmdline) {
        MultiByteToWideChar(CP_UTF8, 0, cmd.c_str(), -1, szCmdline, n);
    } else {
        CloseHandle(hStdIn[0]);
        CloseHandle(hStdIn[1]);
        CloseHandle(hStdOut[0]);
        CloseHandle(hStdOut[1]);
        CloseHandle(hStdErr[0]);
        CloseHandle(hStdErr[1]);
        cerr << "Subprocess::popen(): Failed to allocate memory!" << endl;
        return false;
    }
#else
    szCmdline = new TCHAR[cmd.size() + 1];
    strncpy_s(szCmdline, cmd.size() + 1, cmd.c_str(), _TRUNCATE);
#endif

    if (!CreateProcess(NULL, 
                       szCmdline,    // command line 
                       NULL,         // process security attributes 
                       NULL,         // primary thread security attributes 
                       TRUE,         // handles are inherited 
                       0,            // creation flags 
                       NULL,         // use parent's environment 
                       NULL,         // use parent's current directory 
                       &siStartInfo, // STARTUPINFO pointer 
                       &_info)) {    // receives PROCESS_INFORMATION
        CloseHandle(hStdIn[0]);
        CloseHandle(hStdIn[1]);
        CloseHandle(hStdOut[0]);
        CloseHandle(hStdOut[1]);
        CloseHandle(hStdErr[0]);
        CloseHandle(hStdErr[1]);
        cerr << "Subprocess::popen(): Failed to fork process!" << endl;
        return false;
    }
 
    delete [] szCmdline;

    // close unused ends of pipes
    if (hStdIn[0]  != INVALID_HANDLE_VALUE) CloseHandle(hStdIn[0]);
    if (hStdOut[1] != INVALID_HANDLE_VALUE) CloseHandle(hStdOut[1]);
    if (hStdErr[1] != INVALID_HANDLE_VALUE) CloseHandle(hStdErr[1]);

    // store handles of parent side of pipes
    _stdin  = hStdIn[1];
    _stdout = hStdOut[0];
    _stderr = hStdErr[0];

    return true;
#else
    if (_info.pid != -1 && !poll()) {
        cerr << "Subprocess::popen(): Previously opened process not terminated yet!" << endl;
        return false;
    }

    _info.pid = -1;
    if (_stdin  != -1) close(_stdin);
    if (_stdout != -1) close(_stdout);
    if (_stderr != -1) close(_stderr);
    _stdin = -1;
    _stdout = -1;
    _stderr = -1;
    _status = -1;

    // create pipes for standard input/output
    int fdsin [2] = {-1, -1}; // read, write
    int fdsout[2] = {-1, -1};
    int fdserr[2] = {-1, -1};

    if (rm_in == RM_PIPE && pipe(fdsin) == -1) {
        cerr << "Subprocess::popen(): Failed to create pipe!" << endl;
        return false;
    }

    if (rm_out == RM_PIPE && pipe(fdsout) == -1) {
        if (fdsin[0] != -1) close(fdsin[0]);
        if (fdsin[1] != -1) close(fdsin[1]);
        cerr << "Subprocess::popen(): Failed to create pipe!" << endl;
        return false;
    }

    if (rm_err == RM_PIPE && pipe(fdserr) == -1) {
        if (fdsin[0]  != -1) close(fdsin[0]);
        if (fdsin[1]  != -1) close(fdsin[1]);
        if (fdsout[0] != -1) close(fdsout[0]);
        if (fdsout[1] != -1) close(fdsout[1]);
        cerr << "Subprocess::popen(): Failed to create pipe!" << endl;
        return false;
    }

    // fork this process
    if ((_info.pid = fork()) == -1) {
        if (fdsin[0]  != -1) close(fdsin[0]);
        if (fdsin[1]  != -1) close(fdsin[1]);
        if (fdsout[0] != -1) close(fdsout[0]);
        if (fdsout[1] != -1) close(fdsout[1]);
        if (fdserr[0] != -1) close(fdserr[0]);
        if (fdserr[1] != -1) close(fdserr[1]);
        cerr << "Subprocess::popen(): Failed to fork process!" << endl;
        return false;
    }

    if (_info.pid == 0) {

        // close unused ends of pipes
        if (fdsin [1] != -1) close(fdsin [1]);
        if (fdsout[0] != -1) close(fdsout[0]);
        if (fdserr[0] != -1) close(fdserr[0]);

        // redirect standard input/output
        //
        // TODO
        // See http://www.unixwiz.net/techtips/remap-pipe-fds.html for details
        // on why it could happen that the created pipes use file descriptors
        // which are already either one of the three standard file descriptors.

        if (fdsin[0] != -1) {
            dup2(fdsin[0], 0);
            close(fdsin[0]);
        }
        if (fdsout[1] != -1) {
            dup2(fdsout[1], 1);
            close(fdsout[1]);
        }
        if (rm_err == RM_STDOUT) {
            dup2(1, 2);
        } else if (fdserr[1] != -1) {
            dup2(fdserr[1], 2);
            close(fdserr[1]);
        }

        // redirect standard input/output
        // execute command
        char** argv = NULL;

        argv = new char*[args.size() + 1];
        for (unsigned int i = 0; i < args.size(); i++) {
            argv[i] = const_cast<char*>(args[i].c_str());
        }
        argv[args.size()] = NULL;

        if (env) {
            for (unsigned int i = 0; i < env->size(); ++ i) {
                putenv(const_cast<char*>(env->at(i).c_str()));
            }
        }
        execvp(argv[0], argv);

        cerr << "Subprocess::popen(): Failed to execute command!" << endl;

        // we should have never got here...
        delete [] argv;

        exit(EXIT_FAILURE);

    } else {

        // close unused ends of pipes
        if (fdsin [0] != -1) close(fdsin [0]);
        if (fdsout[1] != -1) close(fdsout[1]);
        if (fdserr[1] != -1) close(fdserr[1]);

        // store file descriptors of parent side of pipes
        _stdin  = fdsin [1];
        _stdout = fdsout[0];
        _stderr = fdserr[0];

        return true;
    }
#endif
}

// ---------------------------------------------------------------------------
bool Subprocess::poll() const
{
#if WINDOWS
    DWORD dwStatus = 0;
    if (GetExitCodeProcess(_info.hProcess, &dwStatus)) {
        _status = static_cast<int>(dwStatus);
        return _status != STILL_ACTIVE;
/*
        This should have been more save in case 259 is used as exit code
        by the process. However, it did not seem to work as expected.

        if (_status == STILL_ACTIVE) {
            // if the process is terminated, this would return WAIT_OBJECT_0
            return WaitForSingleObject(_info.hProcess, 0) != WAIT_TIMEOUT;
        } else {
            return false;
        }
*/
    }
    BASIS_THROW(runtime_error, "GetExitCodeProcess() failed");
#else
    if (waitpid(_info.pid, &_status, WNOHANG | WUNTRACED | WCONTINUED) == _info.pid) {
        BASIS_THROW(runtime_error, "waitpid() failed");
    }
    return WIFEXITED(_status) || WIFSIGNALED(_status);
#endif
}

// ---------------------------------------------------------------------------
bool Subprocess::wait()
{
#if WINDOWS
    if (WaitForSingleObject(_info.hProcess, INFINITE) == WAIT_FAILED) {
        return false;
    }
    DWORD dwStatus = 0;
    BOOL bSuccess = GetExitCodeProcess(_info.hProcess, &dwStatus);
    if (bSuccess) {
        _status = static_cast<int>(dwStatus);
        return true;
    } else return false;
#else
    pid_t pid = waitpid(_info.pid, &_status, 0);
    /*
    #ifdef _DEBUG
        // ignore as for some reason the returned pid in Debug mode
        // is not equal to the pid of the child process
        // TODO figure out why
        return true;
    #endif 
    */
    return pid == _info.pid;
#endif
}

// ---------------------------------------------------------------------------
bool Subprocess::send_signal(int signal)
{
#if WINDOWS
    if (signal == 9)  return kill();
    if (signal == 15) return terminate();
    return false;
#else
    return ::kill(_info.pid, signal) == 0;
#endif
}

// ---------------------------------------------------------------------------
bool Subprocess::terminate()
{
#if WINDOWS
    // note: 130 is the exit code used by Unix shells to indicate CTRL + C
    return TerminateProcess(_info.hProcess, 130) != 0;
#else
    return ::kill(_info.pid, SIGTERM) == 0;
#endif
}

// ---------------------------------------------------------------------------
bool Subprocess::kill()
{
#if WINDOWS
    return terminate();
#else
    return ::kill(_info.pid, SIGKILL) == 0;
#endif
}

// ---------------------------------------------------------------------------
bool Subprocess::signaled() const
{
#if WINDOWS
    DWORD dwStatus = 0;
    if (GetExitCodeProcess(_info.hProcess, &dwStatus)) {
        _status = static_cast<int>(dwStatus);
        return _status == 130;
    }
    BASIS_THROW(runtime_error, "GetExitCodeProcess() failed");
#else
    if (waitpid(_info.pid, &_status, WNOHANG | WUNTRACED | WCONTINUED) == _info.pid) {
        BASIS_THROW(runtime_error, "waitpid() failed");
    }
    return WIFSIGNALED(_status);
#endif
}

// ---------------------------------------------------------------------------
int Subprocess::pid() const
{
#if WINDOWS
    return _info.dwProcessId;
#else
    return _info.pid;
#endif
}

// ---------------------------------------------------------------------------
int Subprocess::returncode() const
{
#if WINDOWS
    return _status;
#else
    return WEXITSTATUS(_status);
#endif
}

// ===========================================================================
// inter-process communication
// ===========================================================================

// ---------------------------------------------------------------------------
bool Subprocess::communicate(std::istream& in, std::ostream& out, std::ostream& err)
{
    const size_t nbuf = 1024;
    char buf[nbuf];

    // write stdin data and close pipe afterwards
#if WINDOWS
    if (_stdin != INVALID_HANDLE_VALUE) {
#else
    if (_stdin != -1) {
#endif
        while (!in.eof()) {
            in.read(buf, nbuf);
            if(in.bad()) return false;
            write(buf, in.gcount());
        }
#if WINDOWS
        CloseHandle(_stdin);
        _stdin = INVALID_HANDLE_VALUE;
#else
        close(_stdin);
        _stdin = -1;
#endif
    }
    // read stdout data and close pipe afterwards
#if WINDOWS
    if (_stdout != INVALID_HANDLE_VALUE) {
#else
    if (_stdout != -1) {
#endif
        while (out.good()) {
            int n = read(buf, nbuf);
            if (n == -1) return false;
            if (n == 0) break;
            out.write(buf, n);
            if (out.bad()) return false;
        }
#if WINDOWS
        CloseHandle(_stdout);
        _stdout = INVALID_HANDLE_VALUE;
#else
        close(_stdout);
        _stdout = -1;
#endif
    }
    // read stdout data and close pipe afterwards
#if WINDOWS
    if (_stderr != INVALID_HANDLE_VALUE) {
#else
    if (_stderr != -1) {
#endif
        while (err.good()) {
            int n = read(buf, nbuf, true);
            if (n == -1) return false;
            if (n == 0) break;
            err.write(buf, n);
            if (err.bad()) return false;
        }
#if WINDOWS
        CloseHandle(_stderr);
        _stderr = INVALID_HANDLE_VALUE;
#else
        close(_stderr);
        _stderr = -1;
#endif
    }
    // wait for subprocess
    return wait();
}

// ---------------------------------------------------------------------------
bool Subprocess::communicate(std::ostream& out, std::ostream& err)
{
    std::istringstream in;
#if WINDOWS
    CloseHandle(_stdin);
    _stdin = INVALID_HANDLE_VALUE;
#else
    close(_stdin);
    _stdin = -1;
#endif
    return communicate(in, out, err);
}

// ---------------------------------------------------------------------------
bool Subprocess::communicate(std::ostream& out)
{
    std::istringstream in;
    std::ostringstream err;
#if WINDOWS
    CloseHandle(_stdin);
    _stdin = INVALID_HANDLE_VALUE;
    CloseHandle(_stderr);
    _stderr = INVALID_HANDLE_VALUE;
#else
    close(_stdin);
    _stdin = -1;
    close(_stderr);
    _stderr = -1;
#endif
    return communicate(in, out, err);
}

// ---------------------------------------------------------------------------
int Subprocess::write(const void* buf, size_t nbuf)
{
#if WINDOWS
    DWORD n;
    if (_stdin == INVALID_HANDLE_VALUE) return -1;
    return WriteFile(_stdin, static_cast<const char*>(buf), nbuf, &n, NULL);
#else
    if (_stdin == -1) return -1;
    return ::write(_stdin, buf, nbuf);
#endif
}

// ---------------------------------------------------------------------------
int Subprocess::read(void* buf, size_t nbuf, bool err)
{
#if WINDOWS
    DWORD n;
    HANDLE h = _stdout;
    if (err && _stderr != INVALID_HANDLE_VALUE) h = _stderr;
    return ReadFile(h, static_cast<char*>(buf), nbuf, &n, NULL) && n > 0;
#else
    int fds = _stdout;
    if (err && _stderr != -1) fds = _stderr;
    return ::read(fds, buf, nbuf);
#endif
}

// ===========================================================================
// static methods
// ===========================================================================

// ---------------------------------------------------------------------------
int Subprocess::call(const CommandLine& cmd)
{
    Subprocess p;
    if (p.popen(cmd) && p.wait()) return p.returncode();
    return -1;
}

// ---------------------------------------------------------------------------
int Subprocess::call(const string& cmd)
{
    Subprocess p;
    if (p.popen(cmd) && p.wait()) return p.returncode();
    return -1;
}


} // namespace basis

} // namespace sbia
