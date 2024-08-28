#!/usr/sbin/dtrace -wqs

#pragma D option bufsize=64m
#pragma D option dynvarsize=32m
#pragma D option switchrate=10hz
#pragma D option strsize=1024

/* Directories to be traced.
   To add extra directories, define them here and 
   add a check in the syscall::open:return clause */
dtrace:::BEGIN
{
INCLUDE_DIR_1="/eniq/data/pmdata";
INCLUDE_DIR_2="/eniq/data/eventdata";
}

/* Trace open filenames.
   This will trap the symlink being opened.*/
syscall::open:entry
{
        self->file=arg0;
}

/* Trace return from open filenames.
   self->file will have the symlink filename. fds[arg0] will have the target file.*/
syscall::open:return
/self->file != 0 && (strstr(copyinstr(self->file), INCLUDE_DIR_1)!= NULL || strstr(copyinstr(self->file), INCLUDE_DIR_2)!= NULL) && cleanpath(copyinstr(self->file)) != fds[arg0].fi_pathname /
{
        printf("linkfile %s %s\n", fds[arg0].fi_pathname, copyinstr(self-> file));
        self -> file=0;
}

/* Trace return form open filenames free up the thread-local variable */
syscall::open:return
{
    self -> file=0;
}



