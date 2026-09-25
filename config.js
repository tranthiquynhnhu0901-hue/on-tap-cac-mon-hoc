// ======================================================
// CẤU HÌNH HỆ THỐNG TRẮC NGHIỆM
// ======================================================
//
// Website được lưu trên GitHub Pages.
// Dữ liệu bài làm được lưu vào Supabase.
//
// LƯU Ý:
// - Chỉ sử dụng Publishable Key / Anon Public Key.
// - TUYỆT ĐỐI không đặt Service Role Key hoặc Secret Key
//   vào file này vì config.js nằm trên website công khai.
// ======================================================

window.APP_CONFIG = {

  // Supabase Project URL
  SUPABASE_URL: "https://sqdfsxocajcfoxwaujyr.supabase.co",

  // Dán toàn bộ Publishable Key của Supabase vào giữa 2 dấu "
  // Key thường bắt đầu bằng: sb_publishable_
  SUPABASE_ANON_KEY: "DAN_PUBLISHABLE_KEY_CUA_SUPABASE_VAO_DAY",

  // false = sử dụng database Supabase thật
  // true  = chỉ chạy chế độ demo/local
  DEMO_FALLBACK: false

};