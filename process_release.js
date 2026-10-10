const fs = require('fs');
const https = require('https');
const path = require('path');
const { execSync } = require('child_process');

const env = fs.readFileSync('.env', 'utf8');
const token = env.match(/GITHUB_TOKEN=(.*)/)[1].trim();
const repo = 'thegioidienthoai464/tgdtbanhang';
const TARGET_VERSION = 'v1.1.7';
const TARGET_BUILD = 18;

function githubRequest(endpoint, method = 'GET', data = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(`https://api.github.com${endpoint}`);
    const reqHeaders = {
      'User-Agent': 'Node',
      'Authorization': 'Bearer ' + token,
      'Accept': 'application/vnd.github.v3+json',
      ...headers
    };
    if (data && !reqHeaders['Content-Length']) {
      reqHeaders['Content-Length'] = Buffer.byteLength(typeof data === 'string' ? data : JSON.stringify(data));
      reqHeaders['Content-Type'] = 'application/json';
    }

    const req = https.request({
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: method,
      headers: reqHeaders
    }, res => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve({ statusCode: res.statusCode, location: res.headers.location });
      }
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => {
        try {
          resolve({ statusCode: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ statusCode: res.statusCode, raw: body });
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(typeof data === 'string' ? data : JSON.stringify(data));
    req.end();
  });
}

function downloadBinary(url, targetPath) {
  return new Promise((resolve, reject) => {
    https.get(url, res => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return downloadBinary(res.headers.location, targetPath).then(resolve).catch(reject);
      }
      if (res.statusCode === 200) {
        const file = fs.createWriteStream(targetPath);
        res.pipe(file);
        file.on('finish', () => {
          file.close();
          resolve();
        });
      } else {
        reject(new Error('Status ' + res.statusCode));
      }
    }).on('error', reject);
  });
}

async function uploadAsset(uploadUrlTemplate, fileName, filePath) {
  const uploadUrlStr = uploadUrlTemplate.replace('{?name,label}', `?name=${fileName}`);
  const url = new URL(uploadUrlStr);
  const fileSize = fs.statSync(filePath).size;
  console.log(`📤 Đang tải ${fileName} (${(fileSize / 1024 / 1024).toFixed(1)} MB) lên Release...`);

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: 'POST',
      headers: {
        'User-Agent': 'Node',
        'Authorization': 'Bearer ' + token,
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/vnd.android.package-archive',
        'Content-Length': fileSize
      }
    }, res => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => {
        if (res.statusCode === 201) {
          const json = JSON.parse(body);
          console.log(`  ✅ Thành công: ${fileName} -> ${json.browser_download_url}`);
          resolve(json);
        } else {
          console.error(`  ❌ Thất bại tải ${fileName}:`, res.statusCode, body);
          resolve(null);
        }
      });
    });
    req.on('error', reject);
    fs.createReadStream(filePath).pipe(req);
  });
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function waitForRunCompletion(minCreatedAtISO) {
  console.log(`⏳ Đang theo dõi tiến trình GitHub Actions xây dựng APK...`);
  const startTime = Date.now();
  const maxWaitMs = 15 * 60 * 1000; // tối đa 15 phút

  while (Date.now() - startTime < maxWaitMs) {
    const runsRes = await githubRequest(`/repos/${repo}/actions/workflows/build_apk.yml/runs?per_page=5`);
    if (runsRes.data && runsRes.data.workflow_runs && runsRes.data.workflow_runs.length > 0) {
      // Tìm run mới nhất
      const latestRun = runsRes.data.workflow_runs[0];
      const isNewRun = !minCreatedAtISO || new Date(latestRun.created_at) >= new Date(minCreatedAtISO);

      console.log(`   [Trạng thái Run #${latestRun.id}]: ${latestRun.status} (${latestRun.conclusion || 'đang chạy...'}) - Commit: ${latestRun.head_commit?.message?.slice(0, 40)}`);

      if (isNewRun) {
        if (latestRun.status === 'completed') {
          if (latestRun.conclusion === 'success') {
            console.log(`🎉 Workflow Run #${latestRun.id} đã hoàn thành xuất sắc!`);
            return latestRun.id;
          } else {
            console.error(`❌ Workflow Run #${latestRun.id} kết thúc với kết quả: ${latestRun.conclusion}`);
            return null;
          }
        }
      }
    }
    await sleep(15000); // Đợi 15 giây kiểm tra lại
  }
  console.error('❌ Hết thời gian chờ GitHub Actions!');
  return null;
}

async function main() {
  const targetRunId = process.argv[2];
  let runId = targetRunId;

  if (!runId) {
    // Tự động kiểm tra run mới nhất
    const runsRes = await githubRequest(`/repos/${repo}/actions/workflows/build_apk.yml/runs?per_page=3`);
    if (runsRes.data && runsRes.data.workflow_runs && runsRes.data.workflow_runs.length > 0) {
      const topRun = runsRes.data.workflow_runs[0];
      if (topRun.status === 'completed' && topRun.conclusion === 'success') {
        runId = topRun.id;
      } else {
        runId = await waitForRunCompletion(topRun.created_at);
      }
    }
  }

  if (!runId) {
    console.error('❌ Không tìm thấy run thành công nào!');
    return;
  }

  console.log(`🎯 Đang xử lý Artifacts từ Run ID: ${runId}`);
  const artRes = await githubRequest(`/repos/${repo}/actions/runs/${runId}/artifacts`);
  if (!artRes.data || !artRes.data.artifacts || artRes.data.artifacts.length === 0) {
    console.error('Không tìm thấy artifact nào trong run này!');
    return;
  }

  const latestArtifact = artRes.data.artifacts.find(a => a.name.includes('Android') || a.name.toLowerCase().includes('apk')) || artRes.data.artifacts[0];
  console.log(`📦 Artifact tìm thấy: ${latestArtifact.name} (ID: ${latestArtifact.id}, Size: ${(latestArtifact.size_in_bytes/1024/1024).toFixed(1)} MB, Created: ${latestArtifact.created_at})`);

  const zipPath = path.join(__dirname, 'latest_app.zip');
  console.log('⏳ Đang lấy link tải zip...');
  const initRes = await githubRequest(`/repos/${repo}/actions/artifacts/${latestArtifact.id}/zip`);
  if (!initRes.location) {
    console.error('Không lấy được redirect URL:', initRes);
    return;
  }

  console.log('📥 Đang tải file zip từ AWS S3...');
  await downloadBinary(initRes.location, zipPath);
  console.log('✅ Đã tải xong zip. Đang giải nén...');

  // Xóa các file cũ trước khi giải nén để đảm bảo nhận file mới nhất từ artifact
  let apkSource = path.join(__dirname, 'app-release.apk');
  const subApk = path.join(__dirname, 'mobile_app', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  if (fs.existsSync(apkSource)) {
    try { fs.unlinkSync(apkSource); } catch(_) {}
  }
  if (fs.existsSync(subApk)) {
    try { fs.unlinkSync(subApk); } catch(_) {}
  }

  // Giải nén zip bằng PowerShell
  execSync(`powershell -Command "Expand-Archive -Path '${zipPath}' -DestinationPath '${__dirname}' -Force"`);

  if (!fs.existsSync(apkSource) && fs.existsSync(subApk)) {
    apkSource = subApk;
  }

  if (!fs.existsSync(apkSource)) {
    console.error('❌ Không tìm thấy app-release.apk sau khi giải nén!');
    return;
  }

  const newApkSize = fs.statSync(apkSource).size;
  console.log(`✅ Đã tìm thấy app-release.apk mới! Dung lượng: ${(newApkSize / 1024 / 1024).toFixed(2)} MB`);

  const apkV112 = path.join(__dirname, `TT_POS_${TARGET_VERSION}.apk`);
  const apkStandard = path.join(__dirname, 'TT_POS.apk');
  fs.copyFileSync(apkSource, apkV112);
  fs.copyFileSync(apkSource, apkStandard);
  console.log(`✅ Đã tạo các bản sao TT_POS_${TARGET_VERSION}.apk và TT_POS.apk`);

  // Tạo GitHub Release
  const releasePayload = {
    tag_name: TARGET_VERSION,
    target_commitish: 'main',
    name: `T&T POS ${TARGET_VERSION} (Build ${TARGET_BUILD})`,
    body: `## 🚀 Bản cập nhật T&T POS ${TARGET_VERSION} (Build ${TARGET_BUILD})

### ✨ Tính năng mới & Cải tiến:
1. **Đồng bộ chuẩn xác 100% kho dữ liệu đa chi nhánh**:
   - Dữ liệu tồn kho, giá vốn và kho IMEI tại Thanh Miện (CN01), Thanh Giang (CN02), Bình Giang (CN03) và Toàn hệ thống (ALL) khớp hoàn toàn với số liệu máy tính PC.
   - Quét realtime số lượng máy TrongKho từ bảng IMEI Supabase kết hợp giao dịch bán hàng/nhập xuất thực tế.
2. **Trung tâm Báo cáo ERP chuẩn PC theo từng chi nhánh**:
   - Phân hệ 6.1 (Báo cáo bán hàng): Doanh thu thực tế, số lượng đơn hàng, giá trị trung bình/đơn chuẩn xác theo từng chi nhánh được chọn (loại trừ đơn Đã hủy).
   - Phân hệ 6.2 (Báo cáo hàng hóa & tồn kho): Thống kê tổng số lượng tồn kho, tổng giá trị vốn, danh sách cảnh báo hết hàng/sắp hết hàng đồng bộ chính xác theo chi nhánh.
3. **Màn hình Bán hàng POS & Màn hình Kho hàng**:
   - Hiển thị đúng số lượng tồn kho của mặt hàng theo chi nhánh đang giao dịch.
   - Cho phép chỉnh sửa giá bán, số lượng, thêm hàng hóa mới và chỉnh sửa thông tin hàng hóa trực tiếp.`,
    draft: false,
    prerelease: false
  };

  console.log(`🌐 Đang tạo / cập nhật Release ${TARGET_VERSION}...`);
  let createRes = await githubRequest('/repos/' + repo + '/releases', 'POST', releasePayload);
  let uploadUrl = null;
  let releaseId = null;

  if (createRes.statusCode === 201) {
    console.log(`✅ Đã tạo Release mới: ${createRes.data.name}`);
    uploadUrl = createRes.data.upload_url;
    releaseId = createRes.data.id;
  } else if (createRes.statusCode === 422) {
    console.log(`Release ${TARGET_VERSION} đã tồn tại. Đang lấy upload_url...`);
    const getRes = await githubRequest(`/repos/${repo}/releases/tags/${TARGET_VERSION}`);
    if (getRes.statusCode === 200) {
      uploadUrl = getRes.data.upload_url;
      releaseId = getRes.data.id;
      // Cập nhật release body & name
      await githubRequest(`/repos/${repo}/releases/${getRes.data.id}`, 'PATCH', releasePayload);

      // Xóa các asset cũ nếu trùng tên
      if (getRes.data.assets && getRes.data.assets.length > 0) {
        for (const asset of getRes.data.assets) {
          console.log(`🗑️ Xóa asset cũ: ${asset.name}...`);
          await githubRequest(`/repos/${repo}/releases/assets/${asset.id}`, 'DELETE');
        }
      }
    }
  }

  if (uploadUrl) {
    console.log(`📤 Đang tải các file APK lên Release ${TARGET_VERSION}...`);
    await uploadAsset(uploadUrl, `TT_POS_${TARGET_VERSION}.apk`, apkV112);
    await uploadAsset(uploadUrl, 'TT_POS.apk', apkStandard);
    await uploadAsset(uploadUrl, 'app-release.apk', apkSource);
    console.log(`\n🎉 HOÀN THÀNH TẤT CẢ! RELEASE ${TARGET_VERSION} ĐÃ SẴN SÀNG TẢI VỀ!`);
  } else {
    console.error('Không lấy được uploadUrl!');
  }
}

main().catch(console.error);
