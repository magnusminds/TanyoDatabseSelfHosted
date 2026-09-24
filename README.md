# Tanyo Database Projects

This repository contains the SQL database projects for the Tanyo application:

- `TanyoLogsDB` contains application logging tables and procedures.
- `TanyoAppDB` contains the application database and references the `TanyoLogsDB` DACPAC.

## Build

Build the projects in dependency order from the repository root:

```powershell
dotnet build .\TanyoLogsDB\TanyoLogsDB.sqlproj
dotnet build .\TanyoAppDB\TanyoAppDB.sqlproj
```

The generated DACPAC files are written to each project's `bin\Debug` directory and are excluded from Git.

## Automatic self-hosted sync

The `Sync from TanyoDatabase` GitHub Actions workflow runs every five minutes. It pulls the private source repository, removes `MASKED WITH (...)` from table definitions, adds `WITH ENCRYPTION` to stored procedures, functions, and views when missing, and commits the transformed project to this repository.

## Security

Instance-level login scripts and passwords are intentionally not stored in this repository. Create logins through the deployment environment or a secure secret-management process, then deploy the database users and roles separately.
