// ==UserScript==
// @name         XCloud Auto Renew Premium
// @namespace    http://tampermonkey.net/
// @version      4.3
// @description  Tự động gia hạn máy XCloudPhone (v4.3 - Floating Bubble Mode)
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
    const CHECK_INTERVAL = 5 * 60 * 1000;
    const UI_ID = 'xcloud-v4-widget';
    
    let isRefreshing = false;
    let nextCheckTime = 0;
    let timerInterval = null;

    function createUI() {
        if (document.getElementById(UI_ID)) return;

        const ui = document.createElement('div');
        ui.id = UI_ID;
        const savedPos = JSON.parse(localStorage.getItem('xcloud_widget_pos') || '{"right":"20px","bottom":"20px"}');
        const isMin = localStorage.getItem('xcloud_widget_minimized') === 'true';

        // Style cơ bản cho Widget
        Object.assign(ui.style, {
            position: 'fixed', top: savedPos.top || 'auto', left: savedPos.left || 'auto',
            right: (savedPos.top || savedPos.left) ? 'auto' : (savedPos.right || '20px'),
            bottom: (savedPos.top || savedPos.left) ? 'auto' : (savedPos.bottom || '20px'),
            background: 'rgba(15, 23, 42, 0.95)', color: 'white', zIndex: '2147483647',
            fontFamily: 'Inter, system-ui, sans-serif',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.5)', border: '1px solid #4f46e5',
            backdropFilter: 'blur(10px)', userSelect: 'none', transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
            overflow: 'hidden', cursor: 'move'
        });

        // Thiết lập kích thước dựa trên trạng thái thu nhỏ
        if (isMin) {
            ui.style.width = '48px'; ui.style.height = '48px'; ui.style.borderRadius = '50%'; ui.style.padding = '0';
        } else {
            ui.style.width = '280px'; ui.style.height = 'auto'; ui.style.borderRadius = '12px'; ui.style.padding = '15px';
        }

        ui.innerHTML = `
            <div id="x-bubble" style="display: ${isMin ? 'flex' : 'none'}; width:100%; height:100%; align-items:center; justify-content:center; position:relative">
                <div id="x-indicator-min" style="width:12px; height:12px; border-radius:50%; background:#94a3b8; box-shadow: 0 0 8px #94a3b8"></div>
                <div style="position:absolute; font-size:8px; bottom:4px; opacity:0.5">XCP</div>
            </div>
            <div id="x-full" style="display: ${isMin ? 'none' : 'block'}">
                <div id="x-header" style="display:flex; justify-content:space-between; align-items:center; padding-bottom:10px; border-bottom:1px solid #334155; margin-bottom:12px">
                    <div style="display:flex; align-items:center; gap:8px">
                        <div id="x-indicator" style="width:8px; height:8px; border-radius:50%; background:#94a3b8"></div>
                        <b style="font-size:12px; letter-spacing:0.5px">XCLOUD RENEW</b>
                    </div>
                    <div style="display:flex; gap:10px; align-items:center">
                        <span id="x-refresh" style="cursor:pointer; font-size:14px; opacity:0.7">🔄</span>
                        <span id="x-toggle" style="cursor:pointer; font-size:18px; opacity:0.7; line-height:1">−</span>
                    </div>
                </div>
                <div id="x-list" style="max-height: 250px; overflow-y: auto; font-size:11px; display:flex; flex-direction:column; gap:8px"></div>
                <div id="x-log" style="font-size:9px; color:#94a3b8; margin-top:10px; border-top:1px dashed #334155; padding-top:8px; text-align:center; font-family:monospace">Ready</div>
            </div>
        `;
        document.body.appendChild(ui);

        // --- Logic Chuyển đổi Bubble / Full ---
        const bubble = document.getElementById('x-bubble');
        const full = document.getElementById('x-full');
        const toggleBtn = document.getElementById('x-toggle');

        const setMin = (min) => {
            if (min) {
                ui.style.width = '48px'; ui.style.height = '48px'; ui.style.borderRadius = '50%'; ui.style.padding = '0';
                bubble.style.display = 'flex'; full.style.display = 'none';
            } else {
                ui.style.width = '280px'; ui.style.height = 'auto'; ui.style.borderRadius = '12px'; ui.style.padding = '15px';
                bubble.style.display = 'none'; full.style.display = 'block';
            }
            localStorage.setItem('xcloud_widget_minimized', min);
        };

        toggleBtn.onclick = (e) => { e.stopPropagation(); setMin(true); };
        bubble.onclick = () => { if (!isDraggingMoved) setMin(false); };

        // --- Logic Kéo thả ---
        let isDragging = false, isDraggingMoved = false, startX, startY, startL, startT;
        
        ui.onmousedown = (e) => {
            isDragging = true; isDraggingMoved = false;
            startX = e.clientX; startY = e.clientY;
            const r = ui.getBoundingClientRect(); startL = r.left; startT = r.top;
            ui.style.transition = 'none';
        };

        document.onmousemove = (e) => {
            if (!isDragging) return;
            const dx = e.clientX - startX; const dy = e.clientY - startY;
            if (Math.abs(dx) > 5 || Math.abs(dy) > 5) isDraggingMoved = true;
            
            let nX = startL + dx, nY = startT + dy;
            nX = Math.max(5, Math.min(nX, window.innerWidth - ui.offsetWidth - 5));
            nY = Math.max(5, Math.min(nY, window.innerHeight - ui.offsetHeight - 5));
            ui.style.left = nX + 'px'; ui.style.top = nY + 'px'; ui.style.right = ui.style.bottom = 'auto';
        };

        document.onmouseup = () => {
            if (!isDragging) return; isDragging = false;
            ui.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)';
            localStorage.setItem('xcloud_widget_pos', JSON.stringify({ left: ui.style.left, top: ui.style.top }));
        };

        document.getElementById('x-refresh').onclick = (e) => { e.stopPropagation(); runAutoRenew(); };
        if (!timerInterval) timerInterval = setInterval(updateCountdown, 1000);
    }

    function updateCountdown() {
        const log = document.getElementById('x-log');
        if (!log || nextCheckTime <= 0 || isRefreshing) return;
        const remain = Math.max(0, Math.round((nextCheckTime - Date.now()) / 1000));
        const m = Math.floor(remain / 60), s = remain % 60;
        log.innerText = `v4.3 | Re-check in: ${m}:${s < 10 ? '0' : ''}${s} | by @Tky567`;
        if (remain <= 0 && !isRefreshing) runAutoRenew();
    }

    function updateStatus(type, message) {
        const ind = document.getElementById('x-indicator');
        const indMin = document.getElementById('x-indicator-min');
        const log = document.getElementById('x-log');
        const ui = document.getElementById(UI_ID);
        if (!log || !ui) return;
        log.innerText = message;
        const colors = { active: '#22c55e', login: '#f59e0b', error: '#ef4444', neutral: '#94a3b8' };
        const color = colors[type] || colors.neutral;
        [ind, indMin].forEach(i => { if(i){ i.style.background = color; i.style.boxShadow = `0 0 8px ${color}`; }});
        ui.style.borderColor = color;
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
                setTimeout(() => location.reload(), 2000); return;
            }
            const data = await res.json();
            const devices = data.data || [];
            listEl.innerHTML = '';
            const now = new Date(), renewGroups = {};

            devices.forEach(d => {
                const endTime = new Date(d.endTime);
                const diffH = (endTime - now) / 36e5;
                const p = Math.min((diffH / MAX_LIMIT) * 100, 100), isU = diffH < 1;
                const item = document.createElement('div');
                item.style.background = 'rgba(30, 41, 59, 0.5)'; item.style.padding = '6px'; item.style.borderRadius = '6px';
                item.innerHTML = `
                    <div style="display:flex; justify-content:space-between; margin-bottom:4px">
                        <span style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis; width:140px; font-weight:500">${d.sessionName}</span>
                        <span style="color:${isU?'#fb7185':'#94a3b8'}">${Math.floor(diffH)}h ${Math.floor((diffH%1)*60)}m</span>
                    </div>
                    <div style="height:3px; background:#334155; border-radius:2px; overflow:hidden"><div style="height:100%; width:${p}%; background:linear-gradient(90deg, ${isU?'#ef4444, #f59e0b':'#6366f1, #a855f7'}); transition: width 1s"></div></div>
                `;
                listEl.appendChild(item);
                if (diffH < RENEW_THRESHOLD) {
                    const hAdd = Math.max(1, Math.floor(MAX_LIMIT - diffH));
                    if (!renewGroups[hAdd]) renewGroups[hAdd] = [];
                    renewGroups[hAdd].push(d.id);
                }
            });

            if (Object.keys(renewGroups).length > 0) {
                updateStatus('active', 'Renewing...');
                for (const [h, ids] of Object.entries(renewGroups)) {
                    await fetch('https://api.xcloudphone.com/rentals/extend', {
                        method: 'POST', credentials: 'include',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ listSessionId: ids, rentalHours: Number(h) })
                    });
                }
                updateStatus('active', 'Success!');
                nextCheckTime = Date.now() + 10000;
            } else {
                updateStatus('active', 'refresh');
                nextCheckTime = Date.now() + CHECK_INTERVAL;
            }
        } catch (e) {
            updateStatus('error', 'Lỗi API');
            nextCheckTime = Date.now() + 10000;
        }
        isRefreshing = false;
    }

    setTimeout(runAutoRenew, 1000);
})();
