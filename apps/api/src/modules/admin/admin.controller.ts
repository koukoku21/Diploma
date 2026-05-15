import { Body, Controller, Delete, Get, Header, Param, Patch, Post, Query, Res, UseGuards } from '@nestjs/common';
import { ServiceCategory } from '@prisma/client';
import { MasterStatus } from '@prisma/client';
import type { Response } from 'express';
import { AdminService } from './admin.service';
import { AdminGuard } from './guards/admin.guard';
import { ReviewMasterDto } from './dto/review-master.dto';
import { TelegramService } from '../telegram/telegram.service';

const ADMIN_HTML = `<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Miraku Admin</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         background: #0f0f0f; color: #e8e8e8; min-height: 100vh; }

  /* ── Login screen ── */
  #login { display: flex; align-items: center; justify-content: center;
           min-height: 100vh; padding: 24px; }
  .login-card { background: #1a1a1a; border: 1px solid #2a2a2a; border-radius: 16px;
                padding: 40px; width: 100%; max-width: 360px; }
  .logo { font-size: 22px; font-weight: 700; color: #c9a84c; margin-bottom: 8px; }
  .logo span { color: #e8e8e8; }
  .subtitle { color: #888; font-size: 13px; margin-bottom: 32px; }

  /* ── Main layout ── */
  #app { display: none; }
  .topbar { background: #1a1a1a; border-bottom: 1px solid #2a2a2a;
            padding: 0 32px; height: 56px; display: flex; align-items: center;
            justify-content: space-between; position: sticky; top: 0; z-index: 10; }
  .topbar-logo { font-size: 18px; font-weight: 700; color: #c9a84c; }
  .topbar-logo span { color: #e8e8e8; }
  .stats { display: flex; gap: 24px; }
  .stat { text-align: center; }
  .stat-value { font-size: 20px; font-weight: 700; color: #c9a84c; }
  .stat-label { font-size: 11px; color: #888; }

  .content { padding: 32px; max-width: 1100px; margin: 0 auto; }

  /* ── Tabs ── */
  .tabs { display: flex; gap: 4px; margin-bottom: 24px;
          background: #1a1a1a; border-radius: 10px; padding: 4px; width: fit-content; }
  .tab { padding: 8px 20px; border-radius: 8px; border: none; background: none;
         color: #888; cursor: pointer; font-size: 13px; font-weight: 500; transition: all .15s; }
  .tab.active { background: #c9a84c; color: #0f0f0f; }

  /* ── Cards ── */
  .cards { display: flex; flex-direction: column; gap: 16px; }
  .card { background: #1a1a1a; border: 1px solid #2a2a2a; border-radius: 12px; padding: 20px; }
  .card-header { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
  .avatar { width: 44px; height: 44px; border-radius: 50%; background: #2a2a2a;
            display: flex; align-items: center; justify-content: center;
            font-size: 18px; font-weight: 600; color: #c9a84c; flex-shrink: 0; }
  .master-name { font-size: 16px; font-weight: 600; }
  .master-meta { font-size: 12px; color: #888; margin-top: 2px; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 20px;
           font-size: 11px; font-weight: 600; }
  .badge-pending { background: #2a2010; color: #c9a84c; }
  .badge-approved { background: #0a2010; color: #4caf50; }
  .badge-rejected { background: #200a0a; color: #f44336; }

  .info-row { display: flex; gap: 24px; flex-wrap: wrap; margin-bottom: 12px; }
  .info-item { font-size: 13px; color: #aaa; }
  .info-item strong { color: #e8e8e8; }

  .specs { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 16px; }
  .spec-chip { background: #252525; border: 1px solid #333; border-radius: 20px;
               padding: 3px 10px; font-size: 12px; color: #ccc; }

  .services { margin-bottom: 16px; }
  .services-title { font-size: 12px; color: #666; margin-bottom: 8px; text-transform: uppercase; letter-spacing: .5px; }
  .service-item { display: flex; justify-content: space-between; padding: 6px 0;
                  border-bottom: 1px solid #222; font-size: 13px; }
  .service-item:last-child { border-bottom: none; }
  .service-price { color: #c9a84c; font-weight: 500; }

  .card-actions { display: flex; gap: 10px; margin-top: 16px; }

  /* ── Forms & inputs ── */
  input[type="password"], input[type="text"] {
    width: 100%; padding: 12px 16px; background: #252525; border: 1px solid #333;
    border-radius: 10px; color: #e8e8e8; font-size: 14px; outline: none;
    margin-bottom: 12px; }
  input:focus { border-color: #c9a84c; }

  button { padding: 11px 20px; border: none; border-radius: 10px; cursor: pointer;
           font-size: 13px; font-weight: 600; transition: all .15s; }
  .btn-primary { background: #c9a84c; color: #0f0f0f; width: 100%; padding: 14px; font-size: 15px; }
  .btn-primary:hover { background: #d4b45f; }
  .btn-approve { background: #1a3a1a; color: #4caf50; border: 1px solid #2a5a2a; }
  .btn-approve:hover { background: #2a5a2a; }
  .btn-reject { background: #3a1a1a; color: #f44336; border: 1px solid #5a2a2a; }
  .btn-reject:hover { background: #5a2a2a; }
  .btn-sm { padding: 7px 14px; font-size: 12px; }

  .empty { text-align: center; padding: 60px 0; color: #555; }
  .empty-icon { font-size: 40px; margin-bottom: 12px; }
  .loading { text-align: center; padding: 40px; color: #666; }
  .error-msg { color: #f44336; font-size: 13px; margin-bottom: 8px; }

  /* ── Portfolio photos ── */
  .portfolio { margin-bottom: 16px; }
  .portfolio-title { font-size: 12px; color: #666; margin-bottom: 8px;
    text-transform: uppercase; letter-spacing: .5px; }
  .photo-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
    gap: 6px; }
  .photo-wrap { position: relative; aspect-ratio: 1; border-radius: 8px; overflow: hidden;
    background: #252525; cursor: pointer; }
  .photo-wrap img { width: 100%; height: 100%; object-fit: cover; transition: opacity .15s; }
  .photo-wrap:hover img { opacity: .85; }
  .photo-cover-badge { position: absolute; bottom: 4px; left: 4px; background: #c9a84c;
    color: #0f0f0f; font-size: 10px; font-weight: 700; padding: 2px 6px;
    border-radius: 4px; }

  /* ── Users table ── */
  .toolbar { display: flex; gap: 12px; margin-bottom: 20px; align-items: center; }
  .search-input { flex: 1; padding: 10px 16px; background: #1a1a1a; border: 1px solid #2a2a2a;
    border-radius: 10px; color: #e8e8e8; font-size: 13px; outline: none; }
  .search-input:focus { border-color: #c9a84c; }
  .btn-search { background: #c9a84c; color: #0f0f0f; padding: 10px 18px; font-size: 13px; }
  table { width: 100%; border-collapse: collapse; }
  th { text-align: left; font-size: 11px; color: #666; text-transform: uppercase;
       letter-spacing: .5px; padding: 8px 12px; border-bottom: 1px solid #222; }
  td { padding: 12px; border-bottom: 1px solid #1e1e1e; font-size: 13px; vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #161616; }
  .user-name { font-weight: 600; }
  .user-phone { color: #888; font-size: 12px; }
  .master-chip { background: #2a2010; color: #c9a84c; padding: 2px 8px;
    border-radius: 20px; font-size: 11px; font-weight: 600; }
  .no-master { color: #444; font-size: 12px; }
  .btn-edit { background: #1e2a3a; color: #5b9bd5; border: 1px solid #2a3a5a;
    padding: 5px 12px; font-size: 12px; }
  .btn-revoke { background: #2a1e10; color: #c9a84c; border: 1px solid #4a3a20;
    padding: 5px 12px; font-size: 12px; }
  .btn-delete { background: #3a1a1a; color: #f44336; border: 1px solid #5a2a2a;
    padding: 5px 12px; font-size: 12px; }
  .btn-hard-delete { background: #5a0000; color: #ff6b6b; border: 1px solid #8a0000;
    padding: 5px 12px; font-size: 12px; }

  /* ── Modal ── */
  .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.7);
    z-index: 100; align-items: center; justify-content: center; }
  .modal-overlay.open { display: flex; }
  .modal { background: #1a1a1a; border: 1px solid #2a2a2a; border-radius: 16px;
    padding: 32px; width: 100%; max-width: 400px; }
  .modal h3 { font-size: 16px; margin-bottom: 20px; }
  .modal label { font-size: 12px; color: #888; display: block; margin-bottom: 6px; }
  .modal-actions { display: flex; gap: 10px; margin-top: 20px; justify-content: flex-end; }
  .btn-cancel { background: #252525; color: #888; border: 1px solid #333; }
  .btn-save { background: #c9a84c; color: #0f0f0f; }
</style>
</head>
<body>

<!-- Login -->
<div id="login">
  <div class="login-card">
    <div class="logo">Miraku<span> Admin</span></div>
    <div class="subtitle">Панель верификации мастеров</div>
    <div id="login-error" class="error-msg" style="display:none"></div>
    <input type="password" id="secret-input" placeholder="Admin secret" autocomplete="off">
    <button class="btn-primary" onclick="doLogin()">Войти</button>
  </div>
</div>

<!-- App -->
<div id="app">
  <div class="topbar">
    <div class="topbar-logo">Miraku<span> Admin</span></div>
    <div class="stats" id="stats">
      <div class="stat"><div class="stat-value" id="s-pending">—</div><div class="stat-label">На проверке</div></div>
      <div class="stat"><div class="stat-value" id="s-masters">—</div><div class="stat-label">Активных мастеров</div></div>
      <div class="stat"><div class="stat-value" id="s-users">—</div><div class="stat-label">Пользователей</div></div>
      <div class="stat"><div class="stat-value" id="s-bookings">—</div><div class="stat-label">Всего записей</div></div>
      <div class="stat"><div class="stat-value" id="s-completed">—</div><div class="stat-label">Завершено</div></div>
      <div class="stat"><div class="stat-value" id="s-revenue">—</div><div class="stat-label">Выручка мес.</div></div>
    </div>
  </div>

  <div class="content">
    <div id="daily-chart" style="display:none;margin-bottom:24px;background:#1a1a1a;border:1px solid #2a2a2a;border-radius:12px;padding:20px">
      <div style="font-size:13px;color:#888;margin-bottom:12px">Активность за 7 дней</div>
      <div id="chart-bars" style="display:flex;align-items:flex-end;gap:8px;height:80px"></div>
      <div id="chart-labels" style="display:flex;gap:8px;margin-top:6px"></div>
    </div>
    <div class="tabs">
      <button class="tab active" onclick="switchTab('PENDING')">На проверке</button>
      <button class="tab" onclick="switchTab('APPROVED')">Одобренные</button>
      <button class="tab" onclick="switchTab('REJECTED')">Отклонённые</button>
      <button class="tab" onclick="switchTab('USERS')">Аккаунты</button>
      <button class="tab" onclick="switchTab('TEMPLATES')">Справочник услуг</button>
      <button class="tab" onclick="switchTab('STORIES_PENDING')">Сторисы</button>
      <button class="tab" onclick="switchTab('STORIES_ACTIVE')">Активные сторисы</button>
    </div>
    <div id="cards" class="cards">
      <div class="loading">Загрузка...</div>
    </div>
  </div>
</div>

<!-- Edit user modal -->
<div class="modal-overlay" id="edit-modal">
  <div class="modal">
    <h3>Редактировать аккаунт</h3>
    <input type="hidden" id="edit-user-id">
    <label>Имя</label>
    <input type="text" id="edit-name" placeholder="Имя пользователя">
    <div class="modal-actions">
      <button class="btn-cancel" onclick="closeEditModal()">Отмена</button>
      <button class="btn-save" onclick="saveUser()">Сохранить</button>
    </div>
  </div>
</div>

<!-- Story create modal -->
<div class="modal-overlay" id="story-modal">
  <div class="modal" style="max-width:480px">
    <h3>Создать сторис</h3>
    <label>Салон</label>
    <select id="story-salon" style="width:100%;padding:12px 16px;background:#252525;border:1px solid #333;border-radius:10px;color:#e8e8e8;font-size:14px;outline:none;margin-bottom:12px;appearance:none">
      <option value="">— Авто (первый салон / создать demo) —</option>
    </select>
    <label>Ссылка на медиа (фото/видео)</label>
    <input type="text" id="story-media" placeholder="https://picsum.photos/seed/story1/600/1000">
    <label>Подпись <span style="color:#555;font-weight:400">(необязательно)</span></label>
    <input type="text" id="story-caption" placeholder="Скидка 20% на маникюр весь апрель!">
    <label>Категория <span style="color:#555;font-weight:400">(необязательно)</span></label>
    <select id="story-category" style="width:100%;padding:12px 16px;background:#252525;border:1px solid #333;border-radius:10px;color:#e8e8e8;font-size:14px;outline:none;margin-bottom:12px;appearance:none">
      <option value="">— Все категории —</option>
      <option value="MANICURE">Маникюр</option>
      <option value="PEDICURE">Педикюр</option>
      <option value="HAIRCUT">Стрижки</option>
      <option value="COLORING">Окрашивание</option>
      <option value="MAKEUP">Макияж</option>
      <option value="LASHES">Ресницы</option>
      <option value="BROWS">Брови</option>
      <option value="SKINCARE">Уход</option>
    </select>
    <label>Пакет</label>
    <select id="story-package" style="width:100%;padding:12px 16px;background:#252525;border:1px solid #333;border-radius:10px;color:#e8e8e8;font-size:14px;outline:none;margin-bottom:12px;appearance:none">
      <option value="DAY">День — 2 990 ₸</option>
      <option value="WEEK" selected>Неделя — 9 990 ₸</option>
      <option value="MONTH">Месяц — 24 990 ₸</option>
    </select>
    <div id="story-error" style="color:#f44336;font-size:13px;margin-bottom:8px;display:none"></div>
    <div class="modal-actions">
      <button class="btn-cancel" onclick="closeStoryModal()">Отмена</button>
      <button class="btn-save" onclick="submitCreateStory()">Создать</button>
    </div>
  </div>
</div>

<!-- Service template modal -->
<div class="modal-overlay" id="template-modal">
  <div class="modal" style="max-width:460px">
    <h3 id="tmpl-modal-title">Новая услуга</h3>
    <label>Категория</label>
    <select id="tmpl-category" style="width:100%;padding:12px 16px;background:#252525;border:1px solid #333;border-radius:10px;color:#e8e8e8;font-size:14px;outline:none;margin-bottom:12px;appearance:none">
      <option value="MANICURE">Маникюр</option>
      <option value="PEDICURE">Педикюр</option>
      <option value="HAIRCUT">Стрижки</option>
      <option value="COLORING">Окрашивание</option>
      <option value="MAKEUP">Макияж</option>
      <option value="LASHES">Ресницы</option>
      <option value="BROWS">Брови</option>
      <option value="SKINCARE">Уход</option>
      <option value="OTHER">Другое</option>
    </select>
    <label>Название (RU)</label>
    <input type="text" id="tmpl-name" placeholder="Маникюр классический">
    <label>Название (KZ) <span style="color:#555;font-weight:400">(необязательно)</span></label>
    <input type="text" id="tmpl-name-kz" placeholder="Классикалық маникюр">
    <div id="tmpl-error" style="color:#f44336;font-size:13px;margin-bottom:8px;display:none"></div>
    <div class="modal-actions">
      <button class="btn-cancel" onclick="closeTemplateModal()">Отмена</button>
      <button class="btn-save" onclick="saveTemplate()">Сохранить</button>
    </div>
  </div>
</div>

<script>
const API = '/api/v1';
let SECRET = '';
let currentTab = 'PENDING';

const SPEC_LABELS = {
  MANICURE: 'Маникюр', PEDICURE: 'Педикюр', HAIRCUT: 'Стрижка',
  COLORING: 'Окрашивание', MAKEUP: 'Макияж', LASHES: 'Ресницы',
  BROWS: 'Брови', SKINCARE: 'Уход за кожей', OTHER: 'Другое',
};

async function api(method, path, body) {
  const res = await fetch(API + path, {
    method,
    headers: { 'Content-Type': 'application/json', 'X-Admin-Secret': SECRET },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(res.status);
  return res.json();
}

async function doLogin() {
  SECRET = document.getElementById('secret-input').value.trim();
  if (!SECRET) return;
  try {
    await api('GET', '/admin/stats');
    document.getElementById('login').style.display = 'none';
    document.getElementById('app').style.display = 'block';
    loadStats();
    loadMasters(currentTab);
  } catch {
    const el = document.getElementById('login-error');
    el.textContent = 'Неверный секрет';
    el.style.display = 'block';
  }
}

document.getElementById('secret-input').addEventListener('keydown', e => {
  if (e.key === 'Enter') doLogin();
});

async function loadStats() {
  try {
    const s = await api('GET', '/admin/stats');
    document.getElementById('s-pending').textContent = s.pendingMasters;
    document.getElementById('s-masters').textContent = s.totalMasters;
    document.getElementById('s-users').textContent = s.totalUsers;
    document.getElementById('s-bookings').textContent = s.totalBookings;
    document.getElementById('s-completed').textContent = s.completedBookings;
    const rev = s.monthRevenue >= 1000
      ? Math.round(s.monthRevenue / 1000) + ' тыс'
      : s.monthRevenue;
    document.getElementById('s-revenue').textContent = rev + ' ₸';
    if (s.dailyStats) renderDailyChart(s.dailyStats);
  } catch {}
}

function renderDailyChart(days) {
  const days_labels = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
  const barsEl = document.getElementById('chart-bars');
  const labelsEl = document.getElementById('chart-labels');
  document.getElementById('daily-chart').style.display = 'block';
  const maxBookings = Math.max(...days.map(d => d.bookings), 1);
  barsEl.innerHTML = days.map(d => {
    const h = Math.max(4, Math.round((d.bookings / maxBookings) * 72));
    const dt = new Date(d.date + 'T00:00:00');
    const isToday = dt.toDateString() === new Date().toDateString();
    const color = isToday ? '#c9a84c' : '#3a3a2a';
    return '<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:4px">' +
      (d.bookings > 0 ? '<span style="font-size:10px;color:#888">' + d.bookings + '</span>' : '<span style="font-size:10px;color:transparent">0</span>') +
      '<div style="width:100%;height:' + h + 'px;background:' + color + ';border-radius:4px;transition:height .3s"></div>' +
    '</div>';
  }).join('');
  labelsEl.innerHTML = days.map(d => {
    const dt = new Date(d.date + 'T00:00:00');
    const label = days_labels[(dt.getDay() + 6) % 7];
    const isToday = dt.toDateString() === new Date().toDateString();
    const color = isToday ? '#c9a84c' : '#555';
    return '<div style="flex:1;text-align:center;font-size:10px;color:' + color + '">' + label + '</div>';
  }).join('');
}

function switchTab(status) {
  currentTab = status;
  const tabKeys = ['PENDING','APPROVED','REJECTED','USERS','TEMPLATES','STORIES_PENDING','STORIES_ACTIVE'];
  document.querySelectorAll('.tab').forEach((t, i) => {
    t.classList.toggle('active', tabKeys[i] === status);
  });
  if (status === 'USERS') loadUsers();
  else if (status === 'TEMPLATES') loadTemplates();
  else if (status === 'STORIES_PENDING') loadStories('PENDING');
  else if (status === 'STORIES_ACTIVE') loadStories('ACTIVE');
  else loadMasters(status);
}

async function loadMasters(status) {
  const el = document.getElementById('cards');
  el.innerHTML = '<div class="loading">Загрузка...</div>';
  try {
    const masters = await api('GET', '/admin/masters?status=' + status);
    if (!masters.length) {
      el.innerHTML = '<div class="empty"><div class="empty-icon">✓</div>Заявок нет</div>';
      return;
    }
    el.innerHTML = masters.map(m => renderCard(m)).join('');
  } catch (e) {
    el.innerHTML = '<div class="empty">Ошибка загрузки</div>';
  }
}

function renderCard(m) {
  const initial = (m.user.name || '?')[0].toUpperCase();
  const badge = { PENDING:'badge-pending', APPROVED:'badge-approved', REJECTED:'badge-rejected' }[m.status];
  const created = new Date(m.createdAt).toLocaleDateString('ru-RU');

  const specs = m.specializations.map(s =>
    '<span class="spec-chip">' + (SPEC_LABELS[s.category] || s.category) + '</span>'
  ).join('');

  const services = m.services.map(s =>
    '<div class="service-item"><span>' + s.title + '</span>' +
    '<span class="service-price">' + s.priceFrom.toLocaleString() + ' ₸ · ' + s.durationMin + ' мин</span></div>'
  ).join('');

  const photos = (m.portfolioPhotos || []).map((p, i) =>
    '<div class="photo-wrap" onclick="window.open(\\'' + p.url + '\\',\\'_blank\\')">' +
      '<img src="' + p.url + '" loading="lazy" alt="фото ' + (i+1) + '">' +
      (p.isCover ? '<div class="photo-cover-badge">Обложка</div>' : '') +
    '</div>'
  ).join('');

  const avatarHtml = m.user.avatarUrl
    ? '<img src="' + m.user.avatarUrl + '" style="width:44px;height:44px;border-radius:50%;object-fit:cover">'
    : '<div class="avatar">' + initial + '</div>';

  const actions = m.status === 'PENDING' ? (
    '<button class="btn-approve btn-sm" onclick="review(\\''+m.id+'\\',\\'APPROVED\\')">✓ Одобрить</button>' +
    '<button class="btn-reject btn-sm" onclick="review(\\''+m.id+'\\',\\'REJECTED\\')">✕ Отклонить</button>'
  ) : m.status === 'APPROVED' ? (
    '<button class="btn-reject btn-sm" onclick="review(\\''+m.id+'\\',\\'SUSPENDED\\')">Приостановить</button>'
  ) : (
    '<button class="btn-approve btn-sm" onclick="review(\\''+m.id+'\\',\\'APPROVED\\')">✓ Одобрить повторно</button>'
  );

  return '<div class="card" id="card-' + m.id + '">' +
    '<div class="card-header">' +
      avatarHtml +
      '<div>' +
        '<div class="master-name">' + (m.user.name || 'Без имени') +
          '<span class="badge ' + badge + '" style="margin-left:8px">' + m.status + '</span>' +
        '</div>' +
        '<div class="master-meta">' + m.user.phone + ' · Заявка от ' + created + '</div>' +
      '</div>' +
    '</div>' +
    '<div class="info-row">' +
      '<div class="info-item"><strong>Адрес:</strong> ' + m.address + '</div>' +
      (m.bio ? '<div class="info-item"><strong>О себе:</strong> ' + m.bio + '</div>' : '') +
    '</div>' +
    '<div class="specs">' + specs + '</div>' +
    (photos ? '<div class="portfolio"><div class="portfolio-title">Портфолио (' + m.portfolioPhotos.length + ' фото)</div><div class="photo-grid">' + photos + '</div></div>' : '<div style="color:#555;font-size:13px;margin-bottom:12px">Фото портфолио не загружены</div>') +
    (services ? '<div class="services"><div class="services-title">Услуги</div>' + services + '</div>' : '') +
    '<div class="card-actions">' + actions + '</div>' +
  '</div>';
}

async function review(masterId, status) {
  try {
    await api('PATCH', '/admin/masters/' + masterId + '/review', { status });
    loadStats();
    loadMasters(currentTab);
  } catch {
    alert('Ошибка при обновлении статуса');
  }
}

// ── Users ──────────────────────────────────────────────────────────
let usersSearchTimer = null;

async function loadUsers(search) {
  const el = document.getElementById('cards');
  el.innerHTML =
    '<div class="toolbar">' +
      '<input class="search-input" id="user-search"' +
      ' placeholder="Поиск по имени или телефону..."' +
      ' oninput="debounceSearch(this.value)"' +
      ' value="' + (search || '') + '">' +
    '</div>' +
    '<div class="loading">Загрузка...</div>';

  try {
    const url = '/admin/users' + (search ? '?search=' + encodeURIComponent(search) : '');
    const users = await api('GET', url);
    const tableEl = el.querySelector('.loading');
    if (!users.length) {
      tableEl.outerHTML = '<div class="empty"><div class="empty-icon">👤</div>Пользователей не найдено</div>';
      return;
    }
    tableEl.outerHTML =
      '<table><thead><tr>' +
      '<th>Пользователь</th><th>Телефон</th><th>Мастер</th>' +
      '<th>Зарегистрирован</th><th style="text-align:right">Действия</th>' +
      '</tr></thead><tbody>' +
      users.map(u => renderUserRow(u)).join('') +
      '</tbody></table>';
  } catch {
    el.querySelector('.loading').outerHTML = '<div class="empty">Ошибка загрузки</div>';
  }
}

function debounceSearch(val) {
  clearTimeout(usersSearchTimer);
  usersSearchTimer = setTimeout(() => loadUsers(val), 400);
}

function renderUserRow(u) {
  const created = new Date(u.createdAt).toLocaleDateString('ru-RU');
  const safeName = (u.name || '').replace(/&/g,'&amp;').replace(/"/g,'&quot;');
  const masterChip = u.masterProfile
    ? '<span class="master-chip">' + u.masterProfile.status + '</span>'
    : '<span class="no-master">—</span>';
  const revokeBtn = u.masterProfile && u.masterProfile.status === 'APPROVED'
    ? '<button class="btn-revoke" onclick="revokeMaster(\\'' + u.masterProfile.id + '\\')">Убрать мастера</button> '
    : '';
  const banBtn = u.isBanned
    ? '<button class="btn-approve" onclick="unbanUser(\\'' + u.id + '\\')">Разблокировать</button> '
    : '<button class="btn-revoke" onclick="banUserPrompt(\\'' + u.id + '\\')">Заблокировать</button> ';
  const bannedBadge = u.isBanned
    ? '<span style="color:#e05a6b;font-size:11px;font-weight:700;margin-left:6px">🚫 БАН</span>'
    : '';
  return '<tr id="urow-' + u.id + '" data-name="' + safeName + '">' +
    '<td><div class="user-name">' + (u.name || '—') + bannedBadge + '</div></td>' +
    '<td class="user-phone">' + u.phone + '</td>' +
    '<td>' + masterChip + '</td>' +
    '<td style="color:#666">' + created + '</td>' +
    '<td style="text-align:right;white-space:nowrap">' +
      '<button class="btn-edit" onclick="openEditModal(\\'' + u.id + '\\',this.closest(\\'tr\\').dataset.name)">Изменить</button> ' +
      revokeBtn +
      banBtn +
      '<button class="btn-delete" onclick="deleteUser(\\'' + u.id + '\\')">Удалить</button> ' +
      '<button class="btn-hard-delete" onclick="hardDeleteUser(\\'' + u.id + '\\')">☠ Навсегда</button>' +
    '</td>' +
  '</tr>';
}

async function banUserPrompt(userId) {
  const reason = prompt('Причина блокировки (необязательно):');
  if (reason === null) return;
  await api('PATCH', '/admin/users/' + userId + '/ban', { reason: reason || undefined });
  loadUsers(document.getElementById('user-search')?.value);
}

async function unbanUser(userId) {
  if (!confirm('Разблокировать пользователя?')) return;
  await api('PATCH', '/admin/users/' + userId + '/unban');
  loadUsers(document.getElementById('user-search')?.value);
}

function openEditModal(userId, name) {
  document.getElementById('edit-user-id').value = userId;
  document.getElementById('edit-name').value = name;
  document.getElementById('edit-modal').classList.add('open');
  setTimeout(() => document.getElementById('edit-name').focus(), 50);
}

function closeEditModal() {
  document.getElementById('edit-modal').classList.remove('open');
}

async function saveUser() {
  const userId = document.getElementById('edit-user-id').value;
  const name = document.getElementById('edit-name').value.trim();
  if (!name) return;
  try {
    await api('PATCH', '/admin/users/' + userId, { name });
    closeEditModal();
    loadUsers(document.getElementById('user-search')?.value || '');
  } catch {
    alert('Ошибка при сохранении');
  }
}

async function deleteUser(userId) {
  if (!confirm('Удалить аккаунт? Пользователь сможет восстановить его при повторном входе.')) return;
  try {
    await api('DELETE', '/admin/users/' + userId);
    loadStats();
    loadUsers(document.getElementById('user-search')?.value || '');
  } catch {
    alert('Ошибка при удалении');
  }
}

async function hardDeleteUser(userId) {
  const row = document.getElementById('urow-' + userId);
  const name = row ? row.dataset.name : userId;
  if (!confirm('⚠️ УДАЛИТЬ НАВСЕГДА: ' + name + '\n\nВсе данные будут уничтожены: профиль, заявка мастера, записи, отзывы. Восстановление невозможно.\n\nПродолжить?')) return;
  try {
    await api('DELETE', '/admin/users/' + userId + '/hard');
    loadStats();
    loadUsers(document.getElementById('user-search')?.value || '');
  } catch {
    alert('Ошибка при удалении');
  }
}

async function revokeMaster(masterId) {
  if (!confirm('Убрать статус мастера? Профиль будет деактивирован.')) return;
  try {
    await api('PATCH', '/admin/masters/' + masterId + '/revoke');
    loadStats();
    loadUsers(document.getElementById('user-search')?.value || '');
  } catch {
    alert('Ошибка при отзыве доступа');
  }
}

// Close modal on overlay click
document.getElementById('edit-modal').addEventListener('click', function(e) {
  if (e.target === this) closeEditModal();
});

// ── Service Templates ─────────────────────────────────────────────

const CATEGORY_ORDER = ['MANICURE','PEDICURE','HAIRCUT','COLORING','MAKEUP','LASHES','BROWS','SKINCARE','OTHER'];
let editingTemplateId = null;

async function loadTemplates() {
  const el = document.getElementById('cards');
  el.innerHTML = '<div class="loading">Загрузка...</div>';
  try {
    const templates = await api('GET', '/admin/service-templates');

    // Group by category
    const grouped = {};
    CATEGORY_ORDER.forEach(c => grouped[c] = []);
    templates.forEach(t => { (grouped[t.category] = grouped[t.category] || []).push(t); });

    let html =
      '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">' +
        '<div style="color:#888;font-size:13px">' + templates.length + ' услуг в справочнике</div>' +
        '<button class="btn-save" onclick="openTemplateModal()">+ Добавить услугу</button>' +
      '</div>';

    CATEGORY_ORDER.forEach(cat => {
      const items = grouped[cat];
      if (!items || !items.length) return;
      html +=
        '<div style="margin-bottom:28px">' +
          '<div class="services-title" style="margin-bottom:10px">' + SPEC_LABELS[cat] + ' (' + items.length + ')</div>' +
          '<table><thead><tr>' +
            '<th>Название (RU)</th><th>Название (KZ)</th><th>Статус</th><th>Мастеров</th><th style="text-align:right">Действия</th>' +
          '</tr></thead><tbody>' +
          items.map(t => renderTemplateRow(t)).join('') +
          '</tbody></table>' +
        '</div>';
    });

    el.innerHTML = html;
  } catch {
    el.innerHTML = '<div class="empty">Ошибка загрузки</div>';
  }
}

function renderTemplateRow(t) {
  const statusBadge = t.isActive
    ? '<span class="badge badge-approved">Активна</span>'
    : '<span class="badge badge-rejected">Скрыта</span>';
  const toggleLabel = t.isActive ? 'Скрыть' : 'Показать';
  const cnt = t._count ? t._count.services : '?';
  const nameEsc = (t.name || '').replace(/'/g, "\\'");
  const kzEsc = (t.nameKz || '').replace(/'/g, "\\'");
  return '<tr>' +
    '<td><strong>' + (t.name || '') + '</strong></td>' +
    '<td style="color:#888">' + (t.nameKz || '—') + '</td>' +
    '<td>' + statusBadge + '</td>' +
    '<td style="color:#888">' + cnt + '</td>' +
    '<td style="text-align:right;white-space:nowrap">' +
      '<button class="btn-edit" onclick="openTemplateModal(\\'' + t.id + '\\',\\'' + nameEsc + '\\',\\'' + kzEsc + '\\',\\'' + t.category + '\\')">Изменить</button> ' +
      '<button class="btn-revoke" onclick="toggleTemplate(\\'' + t.id + '\\',' + (!t.isActive) + ')">' + toggleLabel + '</button> ' +
      (cnt === 0 || cnt === '0' ? '<button class="btn-delete" onclick="deleteTemplate(\\'' + t.id + '\\')">Удалить</button>' : '') +
    '</td>' +
  '</tr>';
}

function openTemplateModal(id, name, nameKz, category) {
  editingTemplateId = id || null;
  document.getElementById('tmpl-modal-title').textContent = id ? 'Редактировать услугу' : 'Новая услуга';
  document.getElementById('tmpl-name').value = name || '';
  document.getElementById('tmpl-name-kz').value = nameKz || '';
  document.getElementById('tmpl-category').value = category || 'MANICURE';
  document.getElementById('tmpl-category').disabled = !!id; // нельзя менять категорию у существующей
  document.getElementById('tmpl-error').style.display = 'none';
  document.getElementById('template-modal').classList.add('open');
  setTimeout(() => document.getElementById('tmpl-name').focus(), 50);
}

function closeTemplateModal() {
  document.getElementById('template-modal').classList.remove('open');
  editingTemplateId = null;
}

async function saveTemplate() {
  const name = document.getElementById('tmpl-name').value.trim();
  const nameKz = document.getElementById('tmpl-name-kz').value.trim() || null;
  const category = document.getElementById('tmpl-category').value;
  const errEl = document.getElementById('tmpl-error');
  if (!name) { errEl.textContent = 'Введите название'; errEl.style.display = 'block'; return; }
  errEl.style.display = 'none';
  try {
    if (editingTemplateId) {
      await api('PATCH', '/admin/service-templates/' + editingTemplateId, { name, nameKz });
    } else {
      await api('POST', '/admin/service-templates', { name, nameKz, category });
    }
    closeTemplateModal();
    loadTemplates();
  } catch {
    errEl.textContent = 'Ошибка при сохранении';
    errEl.style.display = 'block';
  }
}

async function toggleTemplate(id, isActive) {
  try {
    await api('PATCH', '/admin/service-templates/' + id, { isActive });
    loadTemplates();
  } catch { alert('Ошибка'); }
}

async function deleteTemplate(id) {
  if (!confirm('Удалить шаблон услуги?')) return;
  try {
    await api('DELETE', '/admin/service-templates/' + id);
    loadTemplates();
  } catch { alert('Нельзя удалить: услуга используется мастерами.'); }
}

document.getElementById('template-modal').addEventListener('click', function(e) {
  if (e.target === this) closeTemplateModal();
});

// ── Stories ──────────────────────────────────────────────────────────
async function loadStories(status) {
  const el = document.getElementById('cards');
  el.innerHTML = '<div class="loading">Загрузка...</div>';
  try {
    const stories = await api('GET', '/admin/stories?status=' + status);
    const createBtn = status === 'PENDING'
      ? '<div style="display:flex;justify-content:flex-end;margin-bottom:16px">' +
          '<button class="btn-save" onclick="openCreateStoryModal()">+ Создать сторис</button>' +
        '</div>'
      : '';
    if (!stories.length) {
      el.innerHTML = createBtn + '<div class="empty"><div class="empty-icon">' +
        (status === 'PENDING' ? '📋' : '✓') + '</div>' +
        (status === 'PENDING' ? 'Новых сторисов нет' : 'Активных сторисов нет') + '</div>';
      return;
    }
    el.innerHTML = createBtn + stories.map(s => renderStoryCard(s, status)).join('');
  } catch {
    el.innerHTML = '<div class="empty">Ошибка загрузки</div>';
  }
}

function renderStoryCard(s, status) {
  const salon = s.salon ? s.salon.name : 'Неизвестный салон';
  const created = new Date(s.createdAt).toLocaleDateString('ru-RU');
  const expires = s.expiresAt ? new Date(s.expiresAt).toLocaleDateString('ru-RU') : '—';
  const isVideo = s.mediaUrl && /\\.(mp4|mov|webm)$/i.test(s.mediaUrl);
  const mediaHtml = s.mediaUrl
    ? (isVideo
        ? '<video src="' + s.mediaUrl + '" controls style="width:100%;max-height:280px;border-radius:8px;object-fit:cover;margin-bottom:12px"></video>'
        : '<img src="' + s.mediaUrl + '" loading="lazy" style="width:100%;max-height:280px;border-radius:8px;object-fit:cover;margin-bottom:12px;cursor:pointer" onclick="window.open(\\'' + s.mediaUrl + '\\',\\'_blank\\')">')
    : '';
  const categoryLabel = SPEC_LABELS[s.category] || s.category || '—';
  const actions = status === 'PENDING'
    ? '<button class="btn-approve btn-sm" onclick="approveStory(\\''+s.id+'\\')">✓ Опубликовать</button>' +
      '<button class="btn-reject btn-sm" onclick="rejectStoryPrompt(\\''+s.id+'\\')">✕ Отклонить</button>'
    : '<button class="btn-reject btn-sm" onclick="deactivateStory(\\''+s.id+'\\')">Снять с публикации</button>';
  return '<div class="card" id="scard-' + s.id + '">' +
    '<div class="card-header">' +
      '<div class="avatar">🏪</div>' +
      '<div>' +
        '<div class="master-name">' + salon + '</div>' +
        '<div class="master-meta">Создан: ' + created +
          (status === 'ACTIVE' ? ' · Истекает: ' + expires : '') + '</div>' +
      '</div>' +
    '</div>' +
    mediaHtml +
    (s.caption ? '<div style="font-size:14px;margin-bottom:12px;color:#ccc">' + s.caption + '</div>' : '') +
    '<div class="info-row">' +
      '<div class="info-item"><strong>Категория:</strong> ' + categoryLabel + '</div>' +
      '<div class="info-item"><strong>Платный:</strong> ' + (s.isPaid ? 'Да' : 'Нет') + '</div>' +
      (s.viewCount != null ? '<div class="info-item"><strong>Просмотров:</strong> ' + s.viewCount + '</div>' : '') +
    '</div>' +
    '<div class="card-actions">' + actions + '</div>' +
  '</div>';
}

async function approveStory(id) {
  try {
    await api('PATCH', '/admin/stories/' + id + '/approve');
    loadStories('PENDING');
    loadStats();
  } catch { alert('Ошибка при публикации'); }
}

async function rejectStoryPrompt(id) {
  const reason = prompt('Причина отклонения (необязательно):') || 'Отклонено администратором';
  try {
    await api('PATCH', '/admin/stories/' + id + '/reject', { reason });
    loadStories('PENDING');
    loadStats();
  } catch { alert('Ошибка при отклонении'); }
}

async function deactivateStory(id) {
  if (!confirm('Снять сторис с публикации?')) return;
  try {
    await api('PATCH', '/admin/stories/' + id + '/deactivate');
    loadStories('ACTIVE');
    loadStats();
  } catch { alert('Ошибка при деактивации'); }
}

async function openCreateStoryModal() {
  document.getElementById('story-media').value = '';
  document.getElementById('story-caption').value = '';
  document.getElementById('story-category').value = '';
  document.getElementById('story-package').value = 'WEEK';
  document.getElementById('story-error').style.display = 'none';
  // Load salons into dropdown
  const select = document.getElementById('story-salon');
  select.innerHTML = '<option value="">— Авто (первый салон / создать demo) —</option>';
  try {
    const salons = await api('GET', '/admin/salons');
    salons.forEach(s => {
      const opt = document.createElement('option');
      opt.value = s.id;
      opt.textContent = s.name;
      select.appendChild(opt);
    });
  } catch {}
  document.getElementById('story-modal').classList.add('open');
  setTimeout(() => document.getElementById('story-media').focus(), 50);
}

function closeStoryModal() {
  document.getElementById('story-modal').classList.remove('open');
}

async function submitCreateStory() {
  const mediaUrl = document.getElementById('story-media').value.trim();
  const errEl = document.getElementById('story-error');
  if (!mediaUrl) { errEl.textContent = 'Введите ссылку на медиа'; errEl.style.display = 'block'; return; }
  errEl.style.display = 'none';
  const body = {
    salonId: document.getElementById('story-salon').value || undefined,
    mediaUrl,
    caption: document.getElementById('story-caption').value.trim() || undefined,
    category: document.getElementById('story-category').value || undefined,
    packageType: document.getElementById('story-package').value,
  };
  try {
    await api('POST', '/admin/stories', body);
    closeStoryModal();
    loadStories('PENDING');
    loadStats();
  } catch {
    errEl.textContent = 'Ошибка при создании сториса';
    errEl.style.display = 'block';
  }
}

document.getElementById('story-modal').addEventListener('click', function(e) {
  if (e.target === this) closeStoryModal();
});
</script>
</body>
</html>`;

@Controller('admin')
export class AdminController {
  constructor(
    private admin: AdminService,
    private telegram: TelegramService,
  ) {}

  // ─── UI страница (без гарда — защищена паролем на стороне браузера) ──
  @Get()
  @Header('Content-Type', 'text/html')
  getUi(@Res() res: Response) {
    res.send(ADMIN_HTML);
  }

  // ─── API (защищены X-Admin-Secret) ───────────────────────────────────
  @UseGuards(AdminGuard)
  @Get('stats')
  getStats() {
    return this.admin.getStats();
  }

  @UseGuards(AdminGuard)
  @Get('masters')
  getPendingMasters(@Query('status') status?: MasterStatus) {
    return this.admin.getPendingMasters(status ?? MasterStatus.PENDING);
  }

  @UseGuards(AdminGuard)
  @Get('masters/:id')
  getMasterDetail(@Param('id') id: string) {
    return this.admin.getMasterDetail(id);
  }

  @UseGuards(AdminGuard)
  @Patch('masters/:id/review')
  reviewMaster(@Param('id') id: string, @Body() dto: ReviewMasterDto) {
    return this.admin.reviewMaster(id, dto);
  }

  @UseGuards(AdminGuard)
  @Patch('masters/:id/revoke')
  revokeMaster(@Param('id') id: string) {
    return this.admin.revokeMaster(id);
  }

  @UseGuards(AdminGuard)
  @Get('users')
  getUsers(@Query('search') search?: string) {
    return this.admin.getUsers(search);
  }

  @UseGuards(AdminGuard)
  @Patch('users/:id')
  updateUser(@Param('id') id: string, @Body('name') name: string) {
    return this.admin.updateUser(id, name);
  }

  @UseGuards(AdminGuard)
  @Delete('users/:id')
  deleteUser(@Param('id') id: string) {
    return this.admin.deleteUser(id);
  }

  @UseGuards(AdminGuard)
  @Delete('users/:id/hard')
  hardDeleteUser(@Param('id') id: string) {
    return this.admin.hardDeleteUser(id);
  }

  @UseGuards(AdminGuard)
  @Patch('users/:id/ban')
  banUser(@Param('id') id: string, @Body('reason') reason?: string) {
    return this.admin.banUser(id, reason);
  }

  @UseGuards(AdminGuard)
  @Patch('users/:id/unban')
  unbanUser(@Param('id') id: string) {
    return this.admin.unbanUser(id);
  }

  // ─── Справочник услуг ─────────────────────────────────────────────

  @UseGuards(AdminGuard)
  @Get('service-templates')
  listServiceTemplates() {
    return this.admin.listServiceTemplates();
  }

  @UseGuards(AdminGuard)
  @Post('service-templates')
  createServiceTemplate(
    @Body('name') name: string,
    @Body('nameKz') nameKz: string | undefined,
    @Body('category') category: ServiceCategory,
  ) {
    return this.admin.createServiceTemplate({ name, nameKz, category });
  }

  @UseGuards(AdminGuard)
  @Patch('service-templates/:id')
  updateServiceTemplate(
    @Param('id') id: string,
    @Body('name') name: string | undefined,
    @Body('nameKz') nameKz: string | undefined,
    @Body('isActive') isActive: boolean | undefined,
  ) {
    return this.admin.updateServiceTemplate(id, { name, nameKz, isActive });
  }

  @UseGuards(AdminGuard)
  @Delete('service-templates/:id')
  deleteServiceTemplate(@Param('id') id: string) {
    return this.admin.deleteServiceTemplate(id);
  }

  // ─── Сторисы ─────────────────────────────────────────────────────

  @UseGuards(AdminGuard)
  @Get('stories')
  getStories(@Query('status') status: 'PENDING' | 'ACTIVE' = 'PENDING') {
    return status === 'ACTIVE'
      ? this.admin.getActiveStories()
      : this.admin.getPendingStories();
  }

  @UseGuards(AdminGuard)
  @Patch('stories/:id/approve')
  approveStory(@Param('id') id: string) {
    return this.admin.approveStory(id);
  }

  @UseGuards(AdminGuard)
  @Patch('stories/:id/reject')
  rejectStory(@Param('id') id: string, @Body('reason') reason: string) {
    return this.admin.rejectStory(id, reason || 'Отклонено администратором');
  }

  @UseGuards(AdminGuard)
  @Patch('stories/:id/deactivate')
  deactivateStory(@Param('id') id: string) {
    return this.admin.deactivateStory(id);
  }

  @UseGuards(AdminGuard)
  @Get('salons')
  getSalons() {
    return this.admin.listSalons();
  }

  @UseGuards(AdminGuard)
  @Post('stories')
  createStory(
    @Body('salonId') salonId: string | undefined,
    @Body('mediaUrl') mediaUrl: string,
    @Body('caption') caption: string | undefined,
    @Body('category') category: ServiceCategory | undefined,
    @Body('packageType') packageType: 'DAY' | 'WEEK' | 'MONTH',
  ) {
    return this.admin.createStory({ salonId, mediaUrl, caption, category, packageType: packageType as any });
  }

  // ─── Telegram webhook ─────────────────────────────────────────────

  // Зарегистрировать webhook в Telegram (вызвать один раз после деплоя)
  @UseGuards(AdminGuard)
  @Post('telegram/setup-webhook')
  async setupWebhook(@Body('url') url: string) {
    return this.telegram.setWebhook(url);
  }

  // Telegram шлёт сюда callback_query когда нажимают кнопки
  @Post('telegram/webhook')
  async telegramWebhook(@Body() update: any) {
    const cbq = update?.callback_query;
    if (!cbq) return { ok: true };

    const { id: cbqId, data, message } = cbq;
    const chatId    = message?.chat?.id;
    const messageId = message?.message_id;

    const [action, entityId] = (data as string).split(':');

    try {
      if (action === 'approve_story') {
        await this.admin.approveStory(entityId);
        await this.telegram.answerCallbackQuery(cbqId, '✅ Сторис опубликован');
        await this.telegram.editMessageText(chatId, messageId, `✅ *Сторис опубликован*\nID: ${entityId}`);

      } else if (action === 'reject_story') {
        await this.admin.rejectStory(entityId, 'Отклонено через Telegram');
        await this.telegram.answerCallbackQuery(cbqId, '❌ Сторис отклонён');
        await this.telegram.editMessageText(chatId, messageId, `❌ *Сторис отклонён*\nID: ${entityId}`);

      } else if (action === 'approve_master') {
        await this.admin.reviewMaster(entityId, { status: MasterStatus.APPROVED });
        await this.telegram.answerCallbackQuery(cbqId, '✅ Мастер одобрен');
        await this.telegram.editMessageText(chatId, messageId, `✅ *Мастер одобрен*\nID: ${entityId}`);

      } else if (action === 'reject_master') {
        await this.admin.reviewMaster(entityId, { status: MasterStatus.REJECTED });
        await this.telegram.answerCallbackQuery(cbqId, '❌ Мастер отклонён');
        await this.telegram.editMessageText(chatId, messageId, `❌ *Мастер отклонён*\nID: ${entityId}`);
      }
    } catch (_) {
      await this.telegram.answerCallbackQuery(cbqId, 'Ошибка при обработке');
    }

    return { ok: true };
  }
}
