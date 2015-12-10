using System;
using System.IO;

namespace DeleteFirstBackup
{
    class Program
    {
        static void Main(string[] args)
        {
            string dir;
            string fullPath;
            string fileMask;
            string[] foundFiles;
            int count;
            int foundFilesCount;

            count = 5; // maximum number of files
            dir = @"d:\"; //path where backup files stored
            fileMask = "backup_*.bak"; // file mask for backup

            foundFiles = Directory.GetFiles(dir, fileMask);
            foundFilesCount = foundFiles.Length;
            
            if (foundFilesCount > 0)
            {
                if (foundFilesCount - count < 0 )
                {
                    Console.WriteLine("Nothing to delete");
                }
                else
                    for (int i = 0; i < foundFilesCount - count; i++)
                    {
                        fullPath = foundFiles.GetValue(i).ToString();
                        File.Delete(fullPath);
                        Console.WriteLine("Deleted: " + fullPath);
                    }
            }
        }
    }
}
