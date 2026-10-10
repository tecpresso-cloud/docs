/**
 * Live chat widget (Tidio). Same project as the main site.
 */
(function () {
    'use strict';

    var SCRIPT_ID = 'whm-tidio-loader';
    var EXPECTED_SRC = 'https://code.tidio.co/3yoyy8fbkncnexpxqtum0zrmkwlxjaka.js';

    // Pages change without a full reload, so this can run more than once.
    if (window.whmLiveChatInit || document.getElementById(SCRIPT_ID)) {
        return;
    }
    window.whmLiveChatInit = true;

    // Starter serves one default language pack.
    document.tidioChatLang = 'en';

    var script = document.createElement('script');
    script.id = SCRIPT_ID;
    script.src = EXPECTED_SRC;
    script.async = true;
    document.body.appendChild(script);
})();
