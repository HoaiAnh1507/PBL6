# PBL6 - LocketAI Project Structure

## Git Ignore Strategy

### 📁 Project Structure

```
PBL6/
├── .gitignore              # Main project gitignore
├── backend/
│   └── .gitignore         # Backend-specific ignores
├── AI_Server/
│   └── .gitignore         # AI Server-specific ignores
└── mobile/locket_ai/
    └── .gitignore         # Flutter-specific ignores
```

### 🚫 What's Ignored

#### 🔒 **Security & Environment**

- `.env` files (except `.env.example`)
- API keys, credentials, certificates
- Database connection strings
- Secret configuration files

#### 🔧 **Build Artifacts**

- **Backend**: `target/`, `*.jar`, `*.war`
- **AI Server**: `__pycache__/`, `*.pyc`, virtual environments
- **Mobile**: `build/`, `.dart_tool/`, iOS/Android builds

#### 🤖 **AI Models & Data**

- Large model files (`*.h5`, `*.weights`, `*.pt`)
- Training datasets and temp data
- Video files (except samples)
- Jupyter notebook checkpoints

#### 💻 **IDE & OS Files**

- `.idea/`, `.vscode/` (IDE configs)
- `.DS_Store`, `Thumbs.db` (OS files)
- Editor swap files, temporary files

#### 📱 **Mobile Specific**

- iOS: `Pods/`, generated frameworks
- Android: `.gradle/`, `local.properties`
- Generated Dart files (`*.g.dart`)

### ✅ **What's Tracked**

#### 📋 **Configuration Templates**

- `.env.example` files
- Sample configuration files
- Development property templates

#### 🎯 **Source Code**

- All application source code
- Configuration templates
- Documentation and README files
- Sample/test media files

#### 🔧 **Build Configuration**

- `pom.xml`, `pubspec.yaml`
- Gradle build files
- CMake configurations

### 🎬 **Media Files Policy**

- ❌ **Ignored**: Large video files, user uploads
- ✅ **Tracked**: Sample videos for testing (`sample*.mp4`, `test*.mp4`)
- 📁 **Excluded Directories**: `uploads/`, `media/`, `temp_videos/`

### 🚀 **Development Tips**

1. **Environment Setup**: Always copy `.env.example` to `.env` and fill in your values
2. **Model Files**: Download AI models separately (not tracked due to size)
3. **IDE Settings**: Personal IDE settings are ignored, use project-level configs
4. **Database**: Use environment variables for DB connections
5. **Testing**: Sample files in `/test/` directories are tracked

### 📝 **Adding New Ignores**

- **Global items**: Add to root `.gitignore`
- **Component-specific**: Add to respective component's `.gitignore`
- **Temporary ignores**: Use `git update-index --skip-worktree filename`

### 🔍 **Check Ignored Files**

```bash
# See what's being ignored
git status --ignored

# Check if a file would be ignored
git check-ignore filename

# List all ignored files
git ls-files --ignored --exclude-standard
```
