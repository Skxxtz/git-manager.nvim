# Git Manager

This is still under development and isn't fully functional yet. The idea is to make navigation in git repositories faster and more efficient. Currently supported features are:

- Tracking/Untracking files 
- Switching, creating, renaming branches
- Setting remotes
- Setting upstreams
- Merging
- Rebasing

Next features will be:

- Forcing commands
- Deleting upstream branches


## Binds:
| Mode | Key | Action | 
| --------------- | --------------- | --------------- | 
| Always | `q` | Quit | 
| Always | `<Esc>` | Quit | 
| Always | `s` | Enter Status Mode| 
| Always | `S` | Enter Branch Mode| 
| Always | `<C-c>` | Enter Commit View | 
<br>

| Mode | Key | Action | 
| --------------- | --------------- | --------------- | 
| Init | `i` | `git init`| 
<br>
| Mode | Key | Action | 
| --------------- | --------------- | --------------- | 
| Status | `u` | Untrack file - `git reset <file>` | 
| Status | `<C-u>` | Untrack all files - `git reset`| 
| Status | `a` | Add file - `git add <file>` | 
| Status | `<C-a>` | Add all files - `git add .`| 
| Status | `p` | Push to remote - `git push`| 
| Status | `<C-p>r` | Remote Add Mode | 
<br>
| Mode | Key | Action | 
| --------------- | --------------- | --------------- | 
| Branch | `rn` | Rename branch | 
| Branch | `o` | Add new branch, inheriting from this one | 
| Branch | `m` | Merge branch under cursor into current branch | 
| Branch | `bp` | Create branch on the remote |
| Branch | `u` | Set upstream of the branch | 
| Branch | `rb` | Git rebase current branch onto branch under cursor | 
| Branch | `<C-s>` | Delete branch under cursor | 
| Branch | `<CR>` | Swith branch to selected branch | 
<br>
| Mode | Key | Action | 
| --------------- | --------------- | --------------- | 
| Edit | `<C-CR>` | Execute command with current input | 
<br>
| Mode | Key | Action | 
| --------------- | --------------- | --------------- | 
| Commit | `<C-CR>` | Execute commit with current message | 
| Commit | `<UP>` | Get previous commit message | 
| Commit | `<DOWN>` | Get next commit message | 
| Commit | `<C-f>` | Insert `[frontend] ` tag | 
| Commit | `<C-b>` | Insert `[backend] ` tag | 
<br>
