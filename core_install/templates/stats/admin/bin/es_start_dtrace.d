#!/usr/bin/stap

/* Directories to be traced.
   To add extra directories, define them here and 
   add a check in the syscall::openat:return clause */
global INCLUDE_DIR_1="/eniq/data/pmdata";

/*Command to be executed through system().
  system() accept shell command as string. */
global command_1 = "target=\`readlink "
global command_2 = "\` \;if \[ \! \$\{target\} \]\; then echo linkfile "
global command_3 = "\; else echo linkfile \$target "
global command_4 = "\; fi"

/* Trace open filenames.
   This will trap the symlink being opened.*/
probe syscall.open
{
   if(isinstr(filename, INCLUDE_DIR_1)!=NULL)
     {
         /*Running Bash command "target=`readlink filename`;if [ ! "${target}" ];then echo "linkfile $filename $filename"; else echo "linkfile $target $filename";fi"	*/	   
         system(command_1.filename.command_2.filename." ".filename.command_3.filename.command_4)
     }
}



