const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: '.env.local' });

// Configuration
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const BUCKET_NAME = 'distribution';
const STORAGE_PATH = 'isufst_gso.apk';
const APK_LOCAL_PATH = path.join(__dirname, '../apps/mobile_app/build/app/outputs/flutter-apk/app-release.apk');

async function deploy() {
    if (!SUPABASE_URL || !SUPABASE_KEY) {
        console.error('Error: NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not found in .env.local');
        process.exit(1);
    }

    if (!fs.existsSync(APK_LOCAL_PATH)) {
        console.error(`Error: APK not found at ${APK_LOCAL_PATH}. Did you run 'flutter build apk --release'?`);
        process.exit(1);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

    try {
        console.log('🚀 Starting mobile deployment...');

        // 1. Get current version from pubspec.yaml
        const pubspecPath = path.join(__dirname, '../apps/mobile_app/pubspec.yaml');
        const pubspec = fs.readFileSync(pubspecPath, 'utf8');
        const versionMatch = pubspec.match(/version: ([\d\.]+)\+(\d+)/);
        
        if (!versionMatch) {
            console.error('Error: Could not parse version from pubspec.yaml');
            process.exit(1);
        }

        const versionNumber = versionMatch[1];
        const buildNumber = parseInt(versionMatch[2]);

        console.log(`📦 Build details: v${versionNumber} (${buildNumber})`);

        // 2. Clean up old versions (Delete if exists)
        console.log(`🧹 Cleaning up old versions in bucket: ${BUCKET_NAME}...`);
        const { data: listData, error: listError } = await supabase.storage.from(BUCKET_NAME).list();
        
        if (listError) throw listError;
        
        if (listData && listData.length > 0) {
            const filesToRemove = listData.map(f => f.name);
            const { error: deleteError } = await supabase.storage.from(BUCKET_NAME).remove(filesToRemove);
            if (deleteError) console.warn('Warning: Could not delete some files:', deleteError.message);
        }

        // 3. Upload new APK
        console.log('📤 Uploading new APK...');
        const apkBuffer = fs.readFileSync(APK_LOCAL_PATH);
        const { data: uploadData, error: uploadError } = await supabase.storage
            .from(BUCKET_NAME)
            .upload(STORAGE_PATH, apkBuffer, {
                contentType: 'application/vnd.android.package-archive',
                upsert: true
            });

        if (uploadError) throw uploadError;

        // 4. Get Public URL
        const { data: { publicUrl } } = supabase.storage.from(BUCKET_NAME).getPublicUrl(STORAGE_PATH);
        console.log(`🔗 Public URL: ${publicUrl}`);

        // 5. Update Database Record
        console.log('📝 Updating database record...');
        const { error: dbError } = await supabase
            .from('app_versions')
            .insert({
                platform: 'android',
                version_number: versionNumber,
                build_number: buildNumber,
                download_url: publicUrl,
                release_notes: 'Production build release via automated script.',
                is_active: true
            });

        if (dbError) throw dbError;

        console.log('✅ Deployment successful!');
    } catch (err) {
        console.error('❌ Deployment failed:', err.message);
        process.exit(1);
    }
}

deploy();
