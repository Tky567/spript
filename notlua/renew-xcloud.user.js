// ==UserScript==
// @name         XCloud Auto Renew Premium
// @namespace    http://tampermonkey.net/
// @version      4.0
// @description  Tự động gia hạn máy XCloudPhone (v4.0 - Draggable & Minimizable)
// @author       Antigravity x Tky567
// @match        https://app.xcloudphone.com/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=xcloudphone.com
// @grant        none
// @run-at       document-end
// ==/UserScript==

(async function() {
    'use strict';

    const RENEW_THRESHOLD = 4;
    const MAX_LIMIT = 5;
    const FOCUS_COOLDOWN = 60 * 1000;
    const UI_ID = 'xcloud-v4-widget';
    let lastRunTime = 0;
    let isRefreshing = false;

    function createUI() {
        if (document.getElementById(UI_ID)) return;

        const ui = document.createElement('div');
        ui.id = UI_ID;
        
        // Lấy vị trí đã lưu hoặc mặc định
        const savedPos = JSON.parse(localStorage.getItem('xcloud_widget_pos') || '{"bottom":"20px","right":"20px"}');
        const isMin = localStorage.getItem('xcloud_widget_minimized') === 'true';

        Object.assign(ui.style, {
            position: 'fixed', 
            bottom: savedPos.bottom || '20px', 
            right: savedPos.right || '20px', 
            top: savedPos.top || 'auto',
            left: savedPos.left || 'auto',
            width: '280px',
            background: 'rgba(15, 23, 42, 0.95)', color: 'white', zIndex: '2147483647',
            borderRadius: '12px', padding: '15px', fontFamily: 'Inter, system-ui, sans-serif',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.5)', border: '1px solid #4f46e5',
            backdropFilter: 'blur(10px)', transition: 'border-color 0.4s',
            userSelect: 'none'
        });

        ui.innerHTML = `
            <div id="x-header" style="display:flex; justify-content:space-between; align-items:center; cursor:move; padding-bottom:10px; border-bottom:1px solid #334155; margin-bottom:12px">
                <div style="display:flex; align-items:center; gap:8px">
                    <div id="x-indicator" style="width:8px; height:8px; border-radius:50%; background:#94a3b8"></div>
                    <b style="font-size:12px; letter-spacing:0.5px; white-space:nowrap">XCLOUD RENEW</b>
                </div>
                <div style="display:flex; gap:8px; align-items:center">
                    <span id="x-refresh" style="cursor:pointer; font-size:14px; opacity:0.7" title="Làm mới">🔄</span>
                    <span id="x-toggle" style="cursor:pointer; font-size:18px; opacity:0.7; line-height:1" title="Thu nhỏ/Mở rộng">−</span>
                </div>
            </div>
            <div id="x-content" style="display: ${isMin ? 'none' : 'block'}">
                <div id="x-list" style="max-height: 250px; overflow-y: auto; font-size:11px; display:flex; flex-direction:column; gap:8px"></div>
                <div id="x-log" style="font-size:9px; color:#94a3b8; margin-top:10px; border-top:1px dashed #334155; padding-top:8px; text-align:center; font-family:monospace">
                    Ready
                </div>
            </div>
        `;
        document.body.appendChild(ui);

        // --- Logic Thu nhỏ/Mở rộng ---
        const content = document.getElementById('x-content');
        const toggleBtn = document.getElementById('x-toggle');
        toggleBtn.onclick = () => {
            const hidden = content.style.display === 'none';
            content.style.display = hidden ? 'block' : 'none';
            toggleBtn.innerText = hidden ? '−' : '+';
            localStorage.setItem('xcloud_widget_minimized', !hidden);
        };
        if (isMin) toggleBtn.innerText = '+';

        // --- Logic Kéo thả (Draggable) ---
        const header = document.getElementById('x-header');
        let isDragging = false;
        let offset = { x: 0, y: 0 };

        header.onmousedown = (e) => {
            isDragging = true;
            offset.x = e.clientX - ui.getBoundingClientRect().left;
            offset.y = e.clientY - ui.getBoundingClientRect().top;
            ui.style.transition = 'none';
        };

        document.onmousemove = (e) => {
            if (!isDragging) return;
            const x = e.clientX - offset.x;
            const y = e.clientY - offset.y;
            ui.style.left = x + 'px';
            ui.style.top = y + 'px';
            ui.style.bottom = 'auto';
            ui.style.right = 'auto';
        };

        document.onmouseup = () => {
            if (!isDragging) return;
            isDragging = false;
            localStorage.setItem('xcloud_widget_pos', JSON.stringify({
                left: ui.style.left,
                top: ui.style.top
            }));
        };

        document.getElementById('x-refresh').onclick = (e) => {
            e.stopPropagation();
            if (isRefreshing) return;
            lastRunTime = 0;
            runAutoRenew();
        };
    }

    function updateStatus(type, message) {
        const indicator = document.getElementById('x-indicator');
        const log = document.getElementById('x-log');
        const ui = document.getElementById(UI_ID);
        if (!indicator || !log) return;

        log.innerText = message;
        const colors = { active: '#22c55e', login: '#f59e0b', error: '#ef4444', neutral: '#94a3b8' };
        const color = colors[type] || colors.neutral;
        indicator.style.background = color;
        indicator.style.boxShadow = `0 0 8px ${color}`;
        if (type !== 'neutral') ui.style.borderColor = color;
    }

    async function runAutoRenew() {
        if (isRefreshing) return;
        isRefreshing = true;
        createUI();

        const listEl = document.getElementById('x-list');
        try {
            const res = await fetch('https://api.xcloudphone.com/renters/rental-sessions?page=1&limit=50', { credentials: 'include' });
            
            if (res.status === 401) {
                updateStatus('login', 'Session Expired! Reloading...');
                setTimeout(() => location.reload(), 2000);
                return;
            }

            const data = await res.json();
            const devices = data.data || [];
            
            listEl.innerHTML = '';
            const now = new Date();
            const renewGroups = {};

            devices.forEach(d => {
                const endTime = new Date(d.endTime);
                const diffH = (endTime - now) / 36e5;
                const p = Math.min((diffH / MAX_LIMIT) * 100, 100);
                const isUrgent = diffH < 1;

                const item = document.createElement('div');
                item.style.background = 'rgba(30, 41, 59, 0.5)';
                item.style.padding = '6px';
                item.style.borderRadius = '6px';
                item.innerHTML = `
                    <div style="display:flex; justify-content:space-between; margin-bottom:4px">
                        <span style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis; width:140px; font-weight:500">${d.sessionName}</span>
                        <span style="color:${isUrgent ? '#fb7185' : '#94a3b8'}">${Math.floor(diffH)}h ${Math.floor((diffH%1)*60)}m</span>
                    </div>
                    <div style="height:3px; background:#334155; border-radius:2px; overflow:hidden">
                        <div style="height:100%; width:${p}%; background:linear-gradient(90deg, ${isUrgent ? '#ef4444, #f59e0b' : '#6366f1, #a855f7'}); transition: width 1s"></div>
                    </div>
                `;
                listEl.appendChild(item);

                if (diffH < RENEW_THRESHOLD) {
                    const hoursToAdd = Math.max(1, Math.floor(MAX_LIMIT - diffH));
                    if (!renewGroups[hoursToAdd]) renewGroups[hoursToAdd] = [];
                    renewGroups[hoursToAdd].push(d.id);
                }
            });

            if (Object.keys(renewGroups).length > 0) {
                updateStatus('active', 'Đang gia hạn...');
                for (const [hours, ids] of Object.entries(renewGroups)) {
                    const exRes = await fetch('https://api.xcloudphone.com/rentals/extend', {
                        method: 'POST',
                        credentials: 'include',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ listSessionId: ids, rentalHours: Number(hours) })
                    });
                    if (exRes.status === 401) { location.reload(); return; }
                }
                updateStatus('active', 'Gia hạn thành công!');
                setTimeout(runAutoRenew, 5000);
            } else {
                updateStatus('active', `💤 ID: ${localStorage.getItem('userDeviceId')?.substring(0,8) || 'N/A'} | ${new Date().toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}`);
            }
        } catch (e) {
            updateStatus('error', 'Lỗi API');
        }
        lastRunTime = Date.now();
        isRefreshing = false;
    }

    window.addEventListener('focus', () => {
        if (Date.now() - lastRunTime > FOCUS_COOLDOWN) runAutoRenew();
    });

    setTimeout(runAutoRenew, 1000);
})();
