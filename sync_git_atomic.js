const fs = require('fs');
const path = require('path');
const https = require('https');

const envPath = path.join(__dirname, '.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const token = envContent.match(/GITHUB_TOKEN=(.*)/)[1].trim();
const repo = 'thegioidienthoai464/tgdtbanhang';

function githubRequest(method, endpoint, data = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(`https://api.github.com${endpoint}`);
    const bodyStr = data ? JSON.stringify(data) : null;
    const req = https.request({
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'User-Agent': 'Node-Git-Sync',
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        ...(bodyStr ? { 'Content-Length': Buffer.byteLength(bodyStr) } : {})
      }
    }, res => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => {
        try {
          const parsed = body ? JSON.parse(body) : {};
          resolve({ status: res.statusCode, data: parsed });
        } catch(e) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });
    req.on('error', reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function createBlob(filePath, retries = 3) {
  const content = fs.readFileSync(filePath);
  const base64 = content.toString('base64');
  for (let attempt = 1; attempt <= retries; attempt++) {
    const res = await githubRequest('POST', `/repos/${repo}/git/blobs`, {
      content: base64,
      encoding: 'base64'
    });
    if (res.status === 201 && res.data && res.data.sha) {
      return res.data.sha;
    }
    if (attempt < retries && (res.status >= 500 || res.status === 429)) {
      console.log(`⚠️ Thử lại tạo blob cho ${filePath} (lần ${attempt}/${retries})...`);
      await new Promise(r => setTimeout(r, 1500));
      continue;
    }
    throw new Error(`Tạo blob thất bại cho ${filePath}: status ${res.status} ${JSON.stringify(res.data)}`);
  }
}

async function main() {
  console.log('🚀 Bắt đầu tạo commit nguyên tử (Atomic Commit) lên GitHub...');

  // 1. Lấy thông tin commit mới nhất của nhánh main
  const refRes = await githubRequest('GET', `/repos/${repo}/git/ref/heads/main`);
  if (refRes.status !== 200 || !refRes.data.object) {
    throw new Error(`Không lấy được ref main: status ${refRes.status} ${JSON.stringify(refRes.data)}`);
  }
  const parentCommitSha = refRes.data.object.sha;
  console.log(`📌 Parent commit SHA: ${parentCommitSha}`);

  const parentCommitRes = await githubRequest('GET', `/repos/${repo}/git/commits/${parentCommitSha}`);
  const baseTreeSha = parentCommitRes.data?.tree?.sha || parentCommitSha;
  console.log(`🌳 Base Tree SHA: ${baseTreeSha}`);

  // 2. Danh sách các file cần cập nhật
  const filesToCommit = [
    'Index.html',
    'index.html',
    'web_deploy/index.html',
    'Code.js',
    '.claspignore',
    'deploy.js',
    'mobile_app/pubspec.yaml',
    'mobile_app/assets/data/ton_kho_3_chinhanh.json',
    'mobile_app/lib/data/models/product_model.dart',
    'mobile_app/lib/data/models/order_model.dart',
    'mobile_app/lib/data/services/update_service.dart',
    'mobile_app/lib/data/services/lan_printer_service.dart',
    'mobile_app/lib/data/repositories/product_repository.dart',
    'mobile_app/lib/data/repositories/cashbook_repository.dart',
    'mobile_app/lib/ui/features/pos/pos_view_model.dart',
    'mobile_app/lib/ui/features/pos/pos_view.dart',
    'mobile_app/lib/ui/features/inventory/inventory_view_model.dart',
    'mobile_app/lib/ui/features/inventory/inventory_view.dart',
    'mobile_app/lib/ui/features/cashbook/cashbook_view_model.dart',
    'mobile_app/lib/ui/features/cashbook/cashbook_view.dart',
    'mobile_app/lib/ui/features/orders/orders_view.dart',
    'mobile_app/lib/ui/core/app_theme.dart',
    'mobile_app/lib/ui/core/formatters.dart',
    'mobile_app/lib/ui/features/dashboard/dashboard_view.dart',
    'mobile_app/version.json',
    'version.json',
    'web_deploy/version.json',
    'download.html',
    'web_deploy/download.html',
    'process_release.js',
    'sync_git_atomic.js'
  ];

  const treeEntries = [];

  for (const relPath of filesToCommit) {
    const fullPath = path.join(__dirname, relPath);
    if (!fs.existsSync(fullPath)) {
      console.warn(`⚠️ Bỏ qua file không tồn tại: ${relPath}`);
      continue;
    }
    console.log(`📦 Đang tạo blob cho: ${relPath}...`);
    const blobSha = await createBlob(fullPath);
    treeEntries.push({
      path: relPath.replace(/\\/g, '/'),
      mode: '100644',
      type: 'blob',
      sha: blobSha
    });
  }

  // 3. Tạo Git Tree
  console.log('🌳 Đang tạo Git Tree...');
  const treeRes = await githubRequest('POST', `/repos/${repo}/git/trees`, {
    base_tree: baseTreeSha,
    tree: treeEntries
  });
  if (treeRes.status !== 201 || !treeRes.data.sha) {
    throw new Error(`Tạo Tree thất bại: status ${treeRes.status} ${JSON.stringify(treeRes.data)}`);
  }
  const newTreeSha = treeRes.data.sha;
  console.log(`✅ Tree SHA mới: ${newTreeSha}`);

  // 4. Tạo Git Commit
  console.log('📝 Đang tạo Git Commit...');
  const commitMessage = process.argv[2] || 'Cập nhật hệ thống bán hàng';
  const commitRes = await githubRequest('POST', `/repos/${repo}/git/commits`, {
    message: commitMessage,
    tree: newTreeSha,
    parents: [parentCommitSha]
  });
  if (commitRes.status !== 201 || !commitRes.data.sha) {
    throw new Error(`Tạo Commit thất bại: status ${commitRes.status} ${JSON.stringify(commitRes.data)}`);
  }
  const newCommitSha = commitRes.data.sha;
  console.log(`✅ Commit SHA mới: ${newCommitSha}`);

  // 5. Cập nhật nhánh main trỏ tới commit mới
  console.log('🔄 Đang cập nhật ref heads/main...');
  const updateRefRes = await githubRequest('PATCH', `/repos/${repo}/git/refs/heads/main`, {
    sha: newCommitSha,
    force: false
  });
  if (updateRefRes.status !== 200) {
    throw new Error(`Cập nhật ref thất bại: status ${updateRefRes.status} ${JSON.stringify(updateRefRes.data)}`);
  }

  console.log(`\n🎉 THÀNH CÔNG VANG DỘI! ĐÃ PUSH COMMIT: ${newCommitSha}`);
  console.log(`👉 Commit message: "${commitMessage}"`);
  console.log(`🔗 Theo dõi build APK tại: https://github.com/${repo}/actions`);
}

main().catch(err => {
  console.error('❌ Lỗi:', err);
  process.exit(1);
});
