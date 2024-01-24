# A method for the version Control of .mlapp file using associated .m file
1. In the AppDesigner, click the “Save” menu, click the downward arrow, and click “Export to .m File…”
2. Export the .m file with the default name to a directory
3. Add both the .m file and the .mlapp file to the GitHub repository by clicking the “Add file” on the up right corner and choose “Upload files”
4. Upload both files and commit to change
5. Use git clone command to clone the repository to the local computer
6. Make changes as wanted in the .mlapp file in local computer
7. Use the method described in former steps, export the .mlapp file to .m file again, in the same repository, and overwrite the previous .m file
8. Use git add command to choose files to be commited
9. Use git commit command to commit local changes
10. Use git push command to push the changes to the GitHub repository
11. The history of the associated .m file of the .mlapp is tracked
