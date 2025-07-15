#!/bin/bash

# Build script for iLEAPP with code signing and hardened runtime
# This script creates entitlements file and updates spec file automatically

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building iLEAPP with code signing and hardened runtime${NC}"

# Configuration
PROJECT_ROOT="/Users/purelogics-2259/Developer/RunPython/iLEAPP"
SPEC_FILE="$PROJECT_ROOT/scripts/pyinstaller/ileapp_macOS.spec"
ENTITLEMENTS_FILE="$PROJECT_ROOT/scripts/pyinstaller/entitlements.plist"
CODESIGN_IDENTITY="Developer ID Application: SUMURI LLC (M2UAN8S5M3)"

# Step 1: Create entitlements.plist if it doesn't exist
echo -e "${YELLOW}📄 Checking for entitlements.plist...${NC}"
if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    echo -e "${YELLOW}Creating entitlements.plist...${NC}"
    cat > "$ENTITLEMENTS_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Enable hardened runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    
    <!-- Allow execution of JIT-compiled code -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    
    <!-- Allow DYLD environment variables -->
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <true/>
    
    <!-- Disable library validation for Python modules -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    
    <!-- Allow execution of unsigned code -->
    <key>com.apple.security.cs.disable-executable-page-protection</key>
    <true/>
    
    <!-- File system access for input/output operations -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Network access if your app needs it -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- Temporary exception for debugging -->
    <key>com.apple.security.get-task-allow</key>
    <true/>
</dict>
</plist>
EOF
    echo -e "${GREEN}✅ Created entitlements.plist${NC}"
else
    echo -e "${GREEN}✅ entitlements.plist already exists${NC}"
fi

# Step 2: Create backup of original spec file
echo -e "${YELLOW}💾 Creating backup of spec file...${NC}"
cp "$SPEC_FILE" "$SPEC_FILE.backup"

# Step 3: Update spec file with codesign_identity and entitlements_file
echo -e "${YELLOW}🔧 Updating spec file with code signing configuration...${NC}"

# Create the updated spec file
cat > "$SPEC_FILE" << 'EOF'
# -*- mode: python ; coding: utf-8 -*-
a = Analysis(
    ['../../ileapp.py'],
    pathex=['../scripts/artifacts'],
    binaries=[],
    datas=[('../', 'scripts')],
    hiddenimports=[
        'astc_decomp_faster',
        'bencoding',
        'blackboxprotobuf',
        'Crypto.Cipher.AES',
        'ijson',
        'lib2to3.refactor',
        'liblzfse',
        'mdplist',
        'mmh3',
        'nska_deserialize',
        'pandas',
        'pgpy',
        'pillow_heif',
        'xml.etree.ElementTree',
        ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)
pyz = PYZ(a.pure)
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='ileapp',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity="Developer ID Application: SUMURI LLC (M2UAN8S5M3)",
    entitlements_file="/Users/purelogics-2259/Developer/RunPython/iLEAPP/scripts/pyinstaller/entitlements.plist",
)
EOF

echo -e "${GREEN}✅ Updated spec file with code signing configuration${NC}"

# Step 4: Verify code signing identity exists
echo -e "${YELLOW}🔍 Verifying code signing identity...${NC}"
if security find-identity -v -p codesigning | grep -q "SUMURI LLC (M2UAN8S5M3)"; then
    echo -e "${GREEN}✅ Code signing identity found${NC}"
else
    echo -e "${RED}❌ Code signing identity not found!${NC}"
    echo -e "${YELLOW}Available identities:${NC}"
    security find-identity -v -p codesigning
    exit 1
fi

# Step 5: Change to project directory
echo -e "${YELLOW}📁 Changing to project directory...${NC}"
cd "$PROJECT_ROOT"

# Step 6: Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf build/ dist/

# Step 7: Run PyInstaller
echo -e "${YELLOW}🔨 Running PyInstaller...${NC}"
pyinstaller --clean --log-level=DEBUG scripts/pyinstaller/ileapp_macOS.spec

# Step 8: Verify the build
if [ -f "dist/ileapp" ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    
    # Check if it's properly signed
    echo -e "${YELLOW}🔍 Verifying code signature...${NC}"
    codesign --verify --verbose dist/ileapp
    
    # Check hardened runtime
    echo -e "${YELLOW}🔍 Checking hardened runtime...${NC}"
    if codesign -dvvv dist/ileapp 2>&1 | grep -q "Hardened Runtime"; then
        echo -e "${GREEN}✅ Hardened runtime is enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Hardened runtime status unclear${NC}"
    fi
    
    # Display file info
    echo -e "${YELLOW}📊 Executable information:${NC}"
    ls -lh dist/ileapp
    file dist/ileapp
    
    echo -e "${GREEN}🎉 Build completed successfully!${NC}"
    echo -e "${GREEN}📦 Executable location: $PROJECT_ROOT/dist/ileapp${NC}"
    
else
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

# Step 9: Optional - Test the executable
echo -e "${YELLOW}🧪 Testing executable (optional)...${NC}"
read -p "Do you want to test the executable? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Running: ./dist/ileapp --help${NC}"
    ./dist/ileapp --help
fi

echo -e "${GREEN}🏁 Script completed!${NC}"
