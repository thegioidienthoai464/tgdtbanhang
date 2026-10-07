const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = __dirname;
const deployDir = path.join(rootDir, 'web_deploy');

// 1. Tạo thư mục web_deploy nếu chưa có
if (!fs.existsSync(deployDir)) {
  fs.mkdirSync(deployDir, { recursive: true });
}

// 2. Đồng bộ Index.html, logo.png, manifest.json sang web_deploy
const indexHtmlContent = fs.readFileSync(path.join(rootDir, 'Index.html'), 'utf8');
fs.writeFileSync(path.join(deployDir, 'index.html'), indexHtmlContent, 'utf8');

if (fs.existsSync(path.join(rootDir, 'logo.png'))) {
  fs.copyFileSync(path.join(rootDir, 'logo.png'), path.join(deployDir, 'logo.png'));
}

if (fs.existsSync(path.join(rootDir, 'manifest.json'))) {
  fs.copyFileSync(path.join(rootDir, 'manifest.json'), path.join(deployDir, 'manifest.json'));
}

if (fs.existsSync(path.join(rootDir, 'version.json'))) {
  fs.copyFileSync(path.join(rootDir, 'version.json'), path.join(deployDir, 'version.json'));
}



if (fs.existsSync(path.join(rootDir, 'download.html'))) {
  fs.copyFileSync(path.join(rootDir, 'download.html'), path.join(deployDir, 'download.html'));
}

if (fs.existsSync(path.join(rootDir, 'test.html'))) {
  fs.copyFileSync(path.join(rootDir, 'test.html'), path.join(deployDir, 'test.html'));
}

// 3. Đảm bảo có file _redirects cho Netlify SPA
fs.writeFileSync(path.join(deployDir, '_redirects'), '/*  /index.html  200\n', 'utf8');

// 4. Lấy thông tin xác thực từ .env
const envContent = fs.readFileSync(path.join(rootDir, '.env'), 'utf8');
const siteIdMatch = envContent.match(/NETLIFY_SITE_ID=(.+)/);
const tokenMatch = envContent.match(/NETLIFY_AUTH_TOKEN=(.+)/);

if (!siteIdMatch || !tokenMatch) {
  console.error("Lỗi: Không tìm thấy NETLIFY_SITE_ID hoặc NETLIFY_AUTH_TOKEN trong file .env");
  process.exit(1);
}

const siteId = siteIdMatch[1].trim();
const token = tokenMatch[1].trim();

console.log("🚀 Đang tự động triển khai mã nguồn lên Netlify...");

try {
  const output = execSync(`npx netlify deploy --prod --dir="${deployDir}" --site="${siteId}" --auth="${token}"`, {
    encoding: 'utf8',
    stdio: 'pipe'
  });
  console.log(output);
  console.log("✅ TRIỂN KHAI THÀNH CÔNG LÊN NETLIFY!");
} catch (err) {
  console.error("Lỗi deploy:", err.stdout || err.message);
  process.exit(1);
}
