#include <stdio.h>
#include<iostream>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <errno.h>
#include <pwd.h>
#include<dirent.h>
#include<fcntl.h>
#include<time.h>
#include<queue>
#include<ftw.h>
#include<cstring>
#include<sys/stat.h>





#define BUF_SZ 256
#define TRUE 1
#define FALSE 0

using namespace std;
char *getcwd(char *buf,size_t size);

const char* COMMAND_EXIT = "exit";
const char* COMMAND_HELP = "help";
const char* COMMAND_CD = "cd";
const char* COMMAND_IN = "<";
const char* COMMAND_OUT = ">";
const char* COMMAND_PIPE = "|";

const char* COMMAND_PWD = "pwd";
const char* COMMAND_DIR = "dir";
const char* COMMAND_LS = "ls";
const char* COMMAND_ECHO = "echo";
const char* COMMAND_DATE= "date";
const char* COMMAND_ENV = "env";
const char* COMMAND_PSTREE = "pstree";
const char* COMMAND_RM = "rm";
const char* COMMAND_MKDIR = "mkdir";
const char* COMMAND_CP = "cp";
const char* COMMAND_FIND = "find";




enum {// 内置的状态码
	RESULT_NORMAL,
	ERROR_FORK,
	ERROR_COMMAND,
	ERROR_WRONG_PARAMETER,
	ERROR_MISS_PARAMETER,// 重定向符号后缺少文件名
	ERROR_TOO_MANY_PARAMETER,
	ERROR_CD,
	ERROR_SYSTEM,
	ERROR_EXIT,

	ERROR_MANY_IN,/* 重定向的错误信息 */
	ERROR_MANY_OUT,
	ERROR_FILE_NOT_EXIST,
	
	
	ERROR_PIPE,/* 管道的错误信息 */
	ERROR_PIPE_MISS_PARAMETER
};

char username[BUF_SZ];
char hostname[BUF_SZ];
char curPath[BUF_SZ];
char commands[BUF_SZ][BUF_SZ];

int isCommandExist(const char* command);
void getUsername();
void getHostname();
int getCurWorkDir();
int splitCommands(char command[BUF_SZ]);
int callExit();
int callCommand(int commandNum);
int callCommandWithPipe(int left, int right);
int callCommandWithRedi(int left, int right);
int callCd(int commandNum);

int main() {
	
	int result = getCurWorkDir();/* 获取当前工作目录、用户名、主机名 */
	if (ERROR_SYSTEM == result) {
		fprintf(stderr, "\e[31;1mError: System error while getting current work directory.\n\e[0m");
		exit(ERROR_SYSTEM);
	}
	getUsername();
	getHostname();

	
	char argv[BUF_SZ];/* 启动myshell */
	while (TRUE) {
		printf("\e[32;1m%s@%s:%s\e[0m$ ", username, hostname,curPath); // 显示为绿色
		/* 获取用户输入的命令 */
		fgets(argv, BUF_SZ, stdin);
		int len = strlen(argv);
		if (len != BUF_SZ) {
			argv[len-1] = '\0';
		}

		int commandNum = splitCommands(argv);
		
		if (commandNum != 0) { // 用户有输入指令
			if (strcmp(commands[0], COMMAND_EXIT) == 0) { // exit命令
				result = callExit();
				if (ERROR_EXIT == result) {
					exit(-1);
				}
			} else if (strcmp(commands[0], COMMAND_CD) == 0) { // cd命令
				result = callCd(commandNum);
				switch (result) {
					case ERROR_MISS_PARAMETER:
						fprintf(stderr, "\e[31;1mError: 使用命令时丢失参数 \"%s\".\n\e[0m"
							, COMMAND_CD);
						break;
					case ERROR_WRONG_PARAMETER:
						fprintf(stderr, "\e[31;1mError: 没有这个路径 \"%s\".\n\e[0m", commands[1]);
						break;
					case ERROR_TOO_MANY_PARAMETER:
						fprintf(stderr, "\e[31;1mError: 使用命令时参数过多 \"%s\".\n\e[0m"
							, COMMAND_CD);
						break;
					case RESULT_NORMAL: // cd命令正常执行，更新当前工作l目录
						result = getCurWorkDir();
						if (ERROR_SYSTEM == result) {
							fprintf(stderr
								, "\e[31;1mError: 获取当前工作目录时出现系统错误.\n\e[0m");
							exit(ERROR_SYSTEM);
						} else {
							break;
						}
				}
			} else if (strcmp(commands[0], COMMAND_HELP) == 0) { 
				cout<<">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"<<endl;
				cout<<">>>>>>Welcome to lzy's cmd line<<<<<<"<<endl;
				cout<<"You can use the commands as follows:"<<endl;
				cout<<"1. pwd "<<endl;
				cout<<"2. dir <dirname>"<<endl;
				cout<<"3. cd <dirname or path> "<<endl;
				cout<<"4. mkdir <dirname> "<<endl;
				cout<<"5. rm <dirname> "<<endl;
				cout<<"6. rename <old filename> <new filename> "<<endl;
				cout<<"7. find <dirname>"<<endl;
				cout<<"8. date "<<endl;
				cout<<"9. exit "<<endl;
				cout<<"10. ls "<<endl;
				cout<<"11. echo "<<endl;
				cout<<"12. env "<<endl;
				cout<<" 13. pstree"<<endl; 
				cout<<" 14. cp"<<endl; 
				cout<<" 15. <"<<endl; 
				cout<<" 16. >"<<endl; 
				cout<<" 17. |"<<endl; 

				cout<<">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"<<endl;
			  
			  }
			else if (strcmp(commands[0], COMMAND_PWD) == 0) { 
			
			char ptr[80];   
			getcwd(ptr,sizeof(ptr));   //invoke the getcwd() method
			cout<<ptr<<endl;  //print the directory path
			
			}
			else if (strcmp(commands[0], COMMAND_DIR) == 0) { 
				DIR * dir;   //The DIR data type represents a directory stream
				struct dirent* ptr;
				int count = 0;
				char dirname[80];
				cin>>dirname; 
				dir = opendir(dirname);
				if(dir == NULL)
				{
				cout<<"cannot open directory"<<endl;
				}
			while((ptr = readdir(dir)) != NULL)
				{    
				if(strcmp(ptr->d_name, ".") == 0 || strcmp(ptr->d_name, "..") == 0){}
				else
				cout<<ptr->d_name<<" ";
				count++;
				if(count % 8 == 0)
				cout<<endl;
				}
				closedir(dir);
				cout<<endl;
			
			}
			else if (strcmp(commands[0], COMMAND_PSTREE) == 0) { 
			
				pid_t pid = fork();
					if (pid < 0)
					{            
						fprintf(stderr, "Fork Failed");
						return 1;
					}
					else if(pid==0)
					{              
                    execlp("pstree","-p",NULL);
					}
              
				else
				{
					/* wait wait，until child process exit*/
					wait();
				}
			
			}
			else if (strcmp(commands[0], COMMAND_ENV) == 0) { 
				pid_t pid = fork();
				if (pid < 0)
				{               
					fprintf(stderr, "Fork Failed");
					return 1;
				}
					else if(pid==0)
					{
						execlp("env","",NULL);
					}	
				
				else
				{
						/* wait wait，until child process exit*/
						wait();
				}
			
			
			}
			else if (strcmp(commands[0], COMMAND_LS) == 0) { 
			
			  pid_t pid = fork();
				if (pid < 0)
				{	                
					fprintf(stderr, "Fork Failed");
					return 1;
				}
					else if(pid==0)
					{              
						execlp("/bin/ls",cata,NULL);
					}              
				else
				{
							/* wait wait，until child process exit*/
							wait();
				}
			
			
			}
			else if (strcmp(commands[0], COMMAND_CP) == 0) { 
				char cp1[30],cp2[30],buf[buffsize];
				int fd1,fd2;
				int n;
				printf("pleace input the file be copy:\n");
				scanf("%s",cp1);
				fflush(stdin);
				printf("pleace input the new file name:\n");
				scanf("%s",cp2);
				if((fd1=open(cp1,O_RDWR|O_CREAT,0644))==-1)
				printf("open the file false!\n");
				if((n=read(fd1,buf,buffsize))==-1)
				printf("read the file false!\n");
				if((fd2=open(cp2,O_RDWR|O_CREAT,0664))==-1)
				printf("open the file false!\n");
				if(write(fd2,buf,n)==-1)
				printf("open the file false!\n");
				if(close(fd1)==-1)
				printf("close false!\n");
				if(close(fd2)==-1)
				printf("close false!\n");
			
			
			}
			else if (strcmp(commands[0], COMMAND_ECHO) == 0) { 
			
				char dirname[80];
				cin>>dirname;	
				cout<<dirname<<endl;  
			}			
			else if (strcmp(commands[0], COMMAND_MKDIR) == 0) { 
				char filename[20];
				cin >> filename;
				if(mkdir(filename, 0777) == 0)
				{
					cout<<filename<<" indecates successful!!!"<<endl;
				}
				else
					{  
					cout<<filename<<" indecates failure!!!"<<endl;
					}
			}	
			else if (strcmp(commands[0], COMMAND_RM) == 0) { 
					char filename[20];
					cin >> filename;
					if(rmdir(filename) == 0)
					{
						cout<<filename<<" delete successful!!!"<<endl;
					}
					else
						cout<<filename<<" delete failure!!!"<<endl;
			
			}
			else if (strcmp(commands[0], COMMAND_FIND) == 0) { 
				char dirname[50];
				cin>>dirname; 
				ftw(dirname, fn,500);
			
			
			}
			else { // 其它命令
				result = callCommand(commandNum);
				switch (result) {
					case ERROR_FORK:
						fprintf(stderr, "\e[31;1mError: fork函数错误.\n\e[0m");
						exit(ERROR_FORK);
					case ERROR_COMMAND:
						fprintf(stderr, "\e[31;1mError: 指令不存在.\n\e[0m");
						break;
					case ERROR_MANY_IN:
						fprintf(stderr, "\e[31;1mError: 输入重定向符超过一个 \"%s\".\n\e[0m", COMMAND_IN);
						break;
					case ERROR_MANY_OUT:
						fprintf(stderr, "\e[31;1mError: 输出重定向符超过一个 \"%s\".\n\e[0m", COMMAND_OUT);
						break;
					case ERROR_FILE_NOT_EXIST:
						fprintf(stderr, "\e[31;1mError: 输入重定向文件不存在.\n\e[0m");
						break;
					case ERROR_MISS_PARAMETER:
						fprintf(stderr, "\e[31;1mError: 重定向符号后缺少文件名.\n\e[0m");
						break;
					case ERROR_PIPE:
						fprintf(stderr, "\e[31;1mError: 打开管道错误.\n\e[0m");
						break;
					case ERROR_PIPE_MISS_PARAMETER:
						fprintf(stderr, "\e[31;1mError: 管道命令'|'后续没有指令，参数缺失.\n\e[0m");
						break;
				}
			}
		}
	}
}

int isCommandExist(const char* command) { // 判断重定向指令是否存在
	if (command == NULL || strlen(command) == 0) return FALSE;

	int result = TRUE;
	
	int fds[2];
	if (pipe(fds) == -1) {
		result = FALSE;
	} else {/* 暂存输入输出重定向标志 */
		
		int inFd = dup(STDIN_FILENO);
		int outFd = dup(STDOUT_FILENO);
		pid_t pid = vfork();
		if (pid == -1) {
			result = FALSE;
		} else if (pid == 0) {/* 将结果输出重定向到文件标识符 */
		
			
			close(fds[0]);
			dup2(fds[1], STDOUT_FILENO);
			close(fds[1]);

			char tmp[BUF_SZ];
			sprintf(tmp, "command -v %s", command);
			system(tmp);
			exit(1);
		} else {
			waitpid(pid, NULL, 0);/* 输入重定向 */
			
			close(fds[1]);
			dup2(fds[0], STDIN_FILENO);
			close(fds[0]);

			if (getchar() == EOF) { // 没有数据，意味着命令不存在
				result = FALSE;
			}
			
			
			dup2(inFd, STDIN_FILENO);/* 恢复输入、输出重定向 */
			dup2(outFd, STDOUT_FILENO);
		}
	}

	return result;
}

void getUsername() { // 获取当前登录的用户名
	struct passwd* pwd = getpwuid(getuid());
	strcpy(username, pwd->pw_name);
}

void getHostname() { // 获取主机名
	gethostname(hostname, BUF_SZ);
}

int getCurWorkDir() { // 获取当前的工作目录
	char* result = getcwd(curPath, BUF_SZ);
	if (result == NULL)
		return ERROR_SYSTEM;
	else return RESULT_NORMAL;
}

int splitCommands(char command[BUF_SZ]) { // 以空格分割命令， 返回分割得到的字符串个数
	int num = 0;
	int i, j;
	int len = strlen(command);

	for (i=0, j=0; i<len; ++i) {
		if (command[i] != ' ') {
			commands[num][j++] = command[i];//第一个字符串0行0列，第二个0行1列，
		} else {
			if (j != 0) {
				commands[num][j] = '\0';
				++num;
				j = 0;
			}
		}
	}
	if (j != 0) {//判断最后一个字符是否是以空格结尾,加空格的话 num+1
		commands[num][j] = '\0';
		++num;
	}

	return num;
}

int callExit() { // 发送terminal信号退出进程
	pid_t pid = getpid();
	if (kill(pid, SIGTERM) == -1) 
		return ERROR_EXIT;
	else return RESULT_NORMAL;
}

int callCommand(int commandNum) { // 给用户使用的函数，用以执行用户输入的命令
	pid_t pid = fork();
	if (pid == -1) {
		return ERROR_FORK;
	} else if (pid == 0) {
		
		int inFds = dup(STDIN_FILENO);/* 获取标准输入、输出的文件标识符 ,STDIN_FILENO 接收键盘的输入  */
		int outFds = dup(STDOUT_FILENO);//STDOUT_FILENO 向屏幕输出

		int result = callCommandWithPipe(0, commandNum);
		
		
		dup2(inFds, STDIN_FILENO);/* 还原标准输入、输出重定向 */
		dup2(outFds, STDOUT_FILENO);
		exit(result);
	} else {
		int status;
		waitpid(pid, &status, 0);
		return WEXITSTATUS(status);
	}
}

int callCommandWithPipe(int left, int right) { // 所要执行的指令区间[left, right)，可能含有管道
	if (left >= right) return RESULT_NORMAL;
	
	int pipeIdx = -1;/* 判断是否有管道命令 */
	for (int i=left; i<right; ++i) {
		if (strcmp(commands[i], COMMAND_PIPE) == 0) {
			pipeIdx = i;
			break;
		}
	}
	if (pipeIdx == -1) { // 不含有管道命令
		return callCommandWithRedi(left, right);
	} else if (pipeIdx+1 == right) { // 管道命令'|'后续没有指令，参数缺失
		return ERROR_PIPE_MISS_PARAMETER;
	}

	
	int fds[2];/* 执行命令 */
	if (pipe(fds) == -1) {
		return ERROR_PIPE;
	}
	int result = RESULT_NORMAL;
	pid_t pid = vfork();
	if (pid == -1) {
		result = ERROR_FORK;
	} else if (pid == 0) { // 子进程执行单个命令
		close(fds[0]);
		dup2(fds[1], STDOUT_FILENO); // 将标准输出重定向到fds[1]
		close(fds[1]);
		
		result = callCommandWithRedi(left, pipeIdx);
		exit(result);
	} else { // 父进程递归执行后续命令
		int status;
		waitpid(pid, &status, 0);
		int exitCode = WEXITSTATUS(status);// 当WIFEXITED返回非零值时，我们可以用这个宏来提取子进程的返回值，如果子进程调用exit(5)退出，WEXITSTATUS(status)就会返回5；如果子进程调用exit(7)，WEXITSTATUS(status)就会返回7。请注意，如果进程不是正常退出的，也就是说，WIFEXITED返回0，这个值就毫无意义。取得子进程exit（）返回的结束代码，一般会先用WIFEXITED 来判断是否正常结束才能使用此宏
		
		if (exitCode != RESULT_NORMAL) { // 子进程的指令没有正常退出，打印错误信息
			char info[4096] = {0};
			char line[BUF_SZ];
			close(fds[1]);
			dup2(fds[0], STDIN_FILENO); // 将标准输入重定向到fds[0]
			close(fds[0]);
			while(fgets(line, BUF_SZ, stdin) != NULL) { // 读取子进程的错误信息
				strcat(info, line);
			}
			printf("%s", info); // 打印错误信息
			
			result = exitCode;
		} else if (pipeIdx+1 < right){
			close(fds[1]);
			dup2(fds[0], STDIN_FILENO); // 将标准输入重定向到fds[0]
			close(fds[0]);
			result = callCommandWithPipe(pipeIdx+1, right); // 递归执行后续指令
		}
	}

	return result;
}

int callCommandWithRedi(int left, int right) { // 所要执行的指令区间[left, right)，不含管道，可能含有重定向
	if (!isCommandExist(commands[left])) { // 指令不存在
		return ERROR_COMMAND;
	}	

	
	int inNum = 0, outNum = 0;/* 判断是否有重定向 */
	char *inFile = NULL, *outFile = NULL;
	int endIdx = right; // 指令在重定向前的终止下标

	for (int i=left; i<right; ++i) {
		if (strcmp(commands[i], COMMAND_IN) == 0) { // 输入重定向
			++inNum;
			if (i+1 < right)
				inFile = commands[i+1];
			else return ERROR_MISS_PARAMETER; // 重定向符号后缺少文件名

			if (endIdx == right) endIdx = i;
		} else if (strcmp(commands[i], COMMAND_OUT) == 0) { // 输出重定向
			++outNum;
			if (i+1 < right)
				outFile = commands[i+1];
			else return ERROR_MISS_PARAMETER; // 重定向符号后缺少文件名
				
			if (endIdx == right) endIdx = i;
		}
	}
	
	if (inNum == 1) {/* 处理重定向 */
		FILE* fp = fopen(inFile, "r");//只读方式打开文件
		if (fp == NULL) // 输入重定向文件不存在
			return ERROR_FILE_NOT_EXIST;
		
		fclose(fp);
	}
	
	if (inNum > 1) { // 输入重定向符超过一个
		return ERROR_MANY_IN;
	} else if (outNum > 1) { // 输出重定向符超过一个
		return ERROR_MANY_OUT;
	}

	int result = RESULT_NORMAL;
	pid_t pid = vfork();
	if (pid == -1) {
		result = ERROR_FORK;
	} else if (pid == 0) {/* 输入输出重定向 */
		
		if (inNum == 1)
			freopen(inFile, "r", stdin);
		if (outNum == 1)
			freopen(outFile, "w", stdout);//写入方式打开：如果文件不存在新建，存在删除后新建。

		
		char* comm[BUF_SZ];
		for (int i=left; i<endIdx; ++i)/* 执行命令 */
			comm[i] = commands[i];
		comm[endIdx] = NULL;
		execvp(comm[left], comm+left);
		exit(errno); // 执行出错，返回errno
	} else {
		int status;
		waitpid(pid, &status, 0);
		int err = WEXITSTATUS(status); // 读取子进程的返回码

		if (err) { // 返回码不为0，意味着子进程执行出错，用红色字体打印出错信息
			printf("\e[31;1mError: %s\n\e[0m", strerror(err));
		}
	}


	return result;
}

int callCd(int commandNum) { // 执行cd命令
	int result = RESULT_NORMAL;

	if (commandNum < 2) {
		result = ERROR_MISS_PARAMETER;
	} else if (commandNum > 2) {
		result = ERROR_TOO_MANY_PARAMETER;
	} else {
		int ret = chdir(commands[1]);//改变路径成功返回0，失败返回-1
		if (ret) result = ERROR_WRONG_PARAMETER;//ret若不是0，则更改目录失败，打印错误日志
	}

	return result;
}