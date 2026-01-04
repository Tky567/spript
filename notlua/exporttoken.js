(function() {
    const t = localStorage.getItem("token");
    const u = localStorage.getItem("userId");
    const c = localStorage.getItem("cuid");
    
    if (!t || !u || !c) return console.error("❌ THIẾU THÔNG TIN!");
    
    const token = "VIP_" + btoa(unescape(encodeURIComponent(JSON.stringify({t, u, c}))));
    
    console.log(token);
    navigator.clipboard?.writeText(token);
})();
