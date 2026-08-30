Azure DevOps local secrets
=================================

This folder holds local helper scripts and a local PAT file used by the automation scripts.

Files
- `.azdo_pat` — Template file to store your Azure DevOps Personal Access Token (PAT). This file is ignored by Git.

Usage
1. Open `scripts/azdo/.azdo_pat` and set your PAT:

   AZDO_PAT=your_personal_access_token_here

2. In bash, load the PAT into your environment before running scripts:

   source scripts/azdo/.azdo_pat

3. Run any scripts that require `AZDO_PAT` (the scripts will read the variable from the environment).

Security
- Keep `.azdo_pat` local and never commit it.
- The project `.gitignore` has an entry to ignore this file.
