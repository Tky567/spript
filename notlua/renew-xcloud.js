// ==UserScript==
// @name         XCloud Auto Renew Premium
// @namespace    http://tampermonkey.net/
// @version      3.2
// @description  Tự động gia hạn máy XCloudPhone (v3.2 - Auto Reload on 401)
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
    const UI_ID = 'xcloud-v3-widget';
    let lastRunTime = 0;
    let isRefreshing = false;

    function createUI() {
        // Xóa sạch UI cũ nếu tồn tại (Tránh trùng lặp)
        const existing = document.getElementById(UI_ID);
        if (existing) return;

        const ui = document.createElement('div');
        ui.id = UI_ID;
        Object.assign(ui.style, {
            position: 'fixed', bottom: '20px', right: '20px', width: '280px',
            background: 'rgba(15, 23, 42, 0.95)', color: 'white', zIndex: '2147483647',
            borderRadius: '12px', padding: '15px', fontFamily: 'Inter, system-ui, sans-serif',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.5)', border: '1px solid #4f46e5',
            backdropFilter: 'blur(10px)', transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)'
        });

        ui.innerHTML = `
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px; border-bottom:1px solid #334155; padding-bottom:10px">
                <div style="display:flex; align-items:center; gap:8px">
                    <div id="x-indicator" style="width:8px; height:8px; border-radius:50%; background:#94a3b8"></div>
                    <b style="font-size:14px; letter-spacing:0.5px">XCLOUD RENEW</b>
                </div>
                <div style="display:flex; gap:12px; align-items:center">
                    <span id="x-refresh" style="cursor:pointer; font-size:16px; opacity:0.7" title="Làm mới">🔄</span>
                </div>
            </div>
            <div id="x-list" style="max-height: 250px; overflow-y: auto; font-size:12px; display:flex; flex-direction:column; gap:10px"></div>
            <div id="x-log" style="font-size:10px; color:#94a3b8; margin-top:12px; border-top:1px dashed #334155; padding-top:8px; text-align:center; font-family:monospace">
                Đang khởi động...
            </div>
        `;
        document.body.appendChild(ui);

        document.getElementById('x-refresh').onclick = () => {
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
        if (type === 'active') {
            indicator.style.background = '#22c55e';
            indicator.style.boxShadow = '0 0 8px #22c55e';
            ui.style.borderColor = '#4f46e5';
        } else if (type === 'login') {
            indicator.style.background = '#f59e0b';
            indicator.style.boxShadow = '0 0 8px #f59e0b';
            ui.style.borderColor = '#f59e0b';
        } else {
            indicator.style.background = '#ef4444';
            indicator.style.boxShadow = '0 0 8px #ef4444';
            ui.style.borderColor = '#ef4444';
        }
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
                listEl.innerHTML = `
                    <div style="text-align:center; padding:15px; background:rgba(245,158,11,0.1); border-radius:8px">
                        <p style="margin-bottom:12px; color:#fde68a">Phiên hết hạn. Đang làm mới trang...</p>
                        <div class="loader"></div>
                    </div>
                `;
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
                item.style.padding = '8px';
                item.style.borderRadius = '6px';
                item.innerHTML = `
                    <div style="display:flex; justify-content:space-between; margin-bottom:5px">
                        <span style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis; width:150px" title="${d.sessionName}">${d.sessionName}</span>
                        <span style="color:${isUrgent ? '#fb7185' : '#94a3b8'}">${Math.floor(diffH)}h ${Math.floor((diffH%1)*60)}m</span>
                    </div>
                    <div style="height:4px; background:#334155; border-radius:2px; overflow:hidden">
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
                    if (exRes.status === 401) { runAutoRenew(); return; } // Thử lại nếu bỗng dưng mất login
                }
                updateStatus('active', 'Gia hạn thành công!');
                setTimeout(runAutoRenew, 3000);
            } else {
                updateStatus('active', `ID: ${localStorage.getItem('userDeviceId')?.substring(0,8) || 'N/A'} | ${new Date().toLocaleTimeString()}`);
            }
        } catch (e) {
            updateStatus('error', 'Lỗi kết nối API');
        }
        
        lastRunTime = Date.now();
        isRefreshing = false;
    }

    window.addEventListener('focus', () => {
        if (Date.now() - lastRunTime > FOCUS_COOLDOWN) runAutoRenew();
    });

    setTimeout(runAutoRenew, 1000);
})();
