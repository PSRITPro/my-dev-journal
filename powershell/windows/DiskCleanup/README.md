# Disk Cleanup and Disk Space Management Scripts

This repository contains PowerShell scripts designed for managing disk space on Windows systems. These scripts assist with cleaning up disk space, generating detailed reports before and after cleanup, and tracking disk space usage efficiently.

## Directory Structure

- **DiskCleanup.ps1**  
  PowerShell script to perform disk cleanup operations. This script is responsible for removing unnecessary files, such as temporary files and system cache, to free up disk space.

- **GetDiskSpace_AfterCleanup.ps1**  
  PowerShell script to report the disk space usage after performing a cleanup. This script generates an HTML report with detailed information about the available disk space following cleanup.

- **GetDiskSpace_AfterCleanup_withouttable.ps1**  
  PowerShell script that performs similar functions to `GetDiskSpace_AfterCleanup.ps1`, but provides a simpler output format without HTML tables. This is useful for situations where a more straightforward text-based report is preferred.

- **GetDiskSpace_BeforeCleanup.ps1**  
  PowerShell script to calculate and report the disk space usage before cleanup operations. This script provides a baseline measurement of disk usage to help assess the impact of cleanup activities.

## Usage

### DiskCleanup.ps1

1. **Purpose**: Performs disk cleanup operations by removing temporary files and system cache.
2. **How to Run**:
   - Open PowerShell as Administrator.
   - Navigate to the directory containing the script.
   - Execute the script with `.\DiskCleanup.ps1`.

### GetDiskSpace_AfterCleanup.ps1

1. **Purpose**: Reports the disk space usage after cleanup, generating a detailed HTML report.
2. **How to Run**:
   - Open PowerShell as Administrator.
   - Navigate to the directory containing the script.
   - Execute the script with `.\GetDiskSpace_AfterCleanup.ps1`.
   - The script will produce an HTML file detailing disk space available after cleanup.

### GetDiskSpace_AfterCleanup_withouttable.ps1

1. **Purpose**: Provides disk space usage information after cleanup in a simpler, text-based format without HTML tables.
2. **How to Run**:
   - Open PowerShell as Administrator.
   - Navigate to the directory containing the script.
   - Execute the script with `.\GetDiskSpace_AfterCleanup_withouttable.ps1`.
   - The script generates a plain text report of available disk space after cleanup.

### GetDiskSpace_BeforeCleanup.ps1

1. **Purpose**: Reports the disk space usage before any cleanup operations to establish a baseline.
2. **How to Run**:
   - Open PowerShell as Administrator.
   - Navigate to the directory containing the script.
   - Execute the script with `.\GetDiskSpace_BeforeCleanup.ps1`.
   - The script generates a report of disk usage prior to performing any cleanup.

## Configuration

1. **Paths and Directories**: Ensure that paths and directories used in the scripts are configured correctly for your environment.
2. **Permissions**: Administrative privileges may be required to execute disk cleanup operations and access certain directories.

## Notes

- **Backup Important Data**: Always back up important data before performing disk cleanup operations.
- **Customization**: Modify the scripts as necessary to fit specific requirements or configurations in your environment.
- **Scheduling**: Consider scheduling these scripts using Task Scheduler to automate regular cleanup and reporting tasks.
