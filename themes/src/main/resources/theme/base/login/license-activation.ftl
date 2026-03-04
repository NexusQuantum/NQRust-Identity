<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('licenseKey'); section>
    <#if section = "header">
        <style>
            /* ── Nuke ALL Keycloak backgrounds ── */
            *, *::before, *::after { box-sizing: border-box; }

            html {
                background: #f2f2f2 !important;
                background-image: none !important;
                background-color: #f2f2f2 !important;
            }
            body,
            body.login-pf-page,
            .login-pf,
            .login-pf-page,
            .login-pf-page .container,
            .login-pf-page .container-fluid,
            #kc-content,
            #kc-content-wrapper {
                background: #f2f2f2 !important;
                background-image: none !important;
                background-color: #f2f2f2 !important;
            }
            /* Kill pseudo-element polygon decorations */
            body::before, body::after,
            .login-pf-page::before, .login-pf-page::after {
                display: none !important;
                content: none !important;
                background: none !important;
            }

            /* Centre layout */
            body.login-pf-page {
                display: flex !important;
                align-items: flex-start !important;
                justify-content: center !important;
                min-height: 100vh !important;
                padding: 40px 16px !important;
            }
            #kc-content { width: 100%; display: flex; justify-content: center; }

            /* Hide Keycloak header */
            #kc-header, .kc-logo-text, #kc-page-title,
            .login-pf-page .login-pf-header { display: none !important; }

            /* ── Card ── */
            .login-pf-page .card-pf {
                margin: 0 auto !important;
                box-shadow: 0 12px 48px rgba(0,0,0,.09) !important;
                border: 1px solid #e5e5e5 !important;
                border-radius: 20px !important;
                padding: 44px 48px !important;
                max-width: 760px !important;
                width: 100% !important;
                background: #ffffff !important;
            }

            /* ── Logo / title ── */
            .nq-logo { text-align: center; margin-bottom: 14px; }
            .nq-title { text-align: center; font-size: 24px; font-weight: 700; color: #1a1a1a; margin: 0 0 6px; }
            .nq-subtitle { text-align: center; color: #888; font-size: 13px; margin: 0 0 24px; }

            /* ── Language tabs ── */
            .lang-tabs {
                display: flex; gap: 0; margin-bottom: 0;
                border-bottom: 2px solid #eee;
            }
            .lang-tab {
                padding: 9px 22px; font-size: 13px; font-weight: 600;
                color: #999; cursor: pointer; border-bottom: 2px solid transparent;
                margin-bottom: -2px; transition: color .2s, border-color .2s;
                user-select: none;
            }
            .lang-tab:hover { color: #FF6B35; }
            .lang-tab.active { color: #FF6B35; border-bottom-color: #FF6B35; }

            /* ── EULA pane ── */
            .eula-pane { display: none; }
            .eula-pane.active { display: block; }

            .eula-box {
                border: 1px solid #e0e0e0; border-top: none;
                border-radius: 0 0 12px 12px;
                padding: 20px 24px;
                height: 300px;
                overflow-y: auto;
                background: #fafafa;
                font-size: 13px; line-height: 1.75; color: #444;
            }
            .eula-box h2 {
                font-size: 13px; font-weight: 700;
                color: #FF6B35; margin: 18px 0 4px; text-transform: uppercase;
                letter-spacing: .4px;
            }
            .eula-box h2:first-child { margin-top: 0; }
            .eula-box p { margin: 4px 0; }
            .eula-box ul { padding-left: 20px; margin: 4px 0; }
            .eula-box ul li { margin: 2px 0; }

            /* ── Scroll hint – keeps space with visibility ── */
            .scroll-hint {
                font-size: 11.5px; color: #bbb;
                text-align: right; margin: 6px 0 12px;
                visibility: visible; transition: opacity .4s;
            }
            .scroll-hint.done { visibility: hidden; opacity: 0; }

            /* ── Checkbox row ── */
            #agree-row {
                display: flex; align-items: flex-start; gap: 10px;
                padding: 13px 16px;
                background: #fff5f0;
                border: 1px solid #fdd9c9;
                border-radius: 10px;
                margin-bottom: 24px;
                transition: background .25s, border-color .25s;
            }
            #agree-row.enabled { background: #fff; border-color: #FF6B35; }
            #agree-checkbox {
                margin-top: 2px; width: 17px; height: 17px;
                accent-color: #FF6B35; cursor: pointer; flex-shrink: 0;
            }
            #agree-checkbox:disabled { opacity: .4; cursor: not-allowed; }
            #agree-label { font-size: 13px; color: #555; cursor: pointer; line-height: 1.5; }

            /* ── License form ── */
            #license-form-section { display: none; animation: fadeUp .3s ease; }
            #license-form-section.visible { display: block; }
            @keyframes fadeUp { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; } }

            /* inputs */
            .nq-label { display: block; font-weight: 600; font-size: 13px; margin-bottom: 8px; color: #333; }
            .nq-input-wrap { position: relative; margin-bottom: 18px; }
            .nq-input-wrap svg { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #bbb; }
            .nq-input {
                width: 100%; height: 46px; padding: 0 14px 0 40px;
                border: 1px solid #ddd; border-radius: 10px;
                font-size: 14px; outline: none; transition: border-color .2s;
            }
            .nq-input:focus { border-color: #FF6B35; }
            .nq-btn {
                display: block; width: 100%; height: 50px;
                background: #FF6B35; color: #fff;
                border: none; border-radius: 10px;
                font-size: 15px; font-weight: 700; cursor: pointer;
                transition: background .2s;
            }
            .nq-btn:hover { background: #e85a24; }
            .nq-divider {
                text-align: center; color: #ccc; margin: 20px 0; font-size: 13px;
                position: relative;
            }
            .nq-divider::before, .nq-divider::after {
                content: ''; display: inline-block;
                width: calc(50% - 22px); height: 1px;
                background: #eee; vertical-align: middle; margin: 0 6px;
            }
            .nq-upload {
                border: 2px dashed #FF6B35; border-radius: 10px;
                padding: 26px; text-align: center; background: #fff9f6; cursor: pointer;
                transition: background .2s;
            }
            .nq-upload:hover { background: #ffeee6; }
            .nq-upload-title { font-weight: 700; color: #333; font-size: 13px; margin-top: 6px; }
            .nq-upload-sub { font-size: 11.5px; color: #999; margin-top: 3px; }
            .alert-error { border-radius: 10px !important; margin-bottom: 20px !important; }
        </style>
        License Activation
    <#elseif section = "form">
        <div id="kc-license-activation">
            <!-- Logo -->
            <div class="nq-logo">
                <svg width="44" height="44" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M20 20L80 80M80 20L20 80" stroke="#FF6B35" stroke-width="12" stroke-linecap="round"/>
                </svg>
            </div>
            <h1 class="nq-title">License Activation</h1>
            <p class="nq-subtitle">Please read and accept the End User License Agreement before activating your license.</p>

            <!-- Language tabs -->
            <div class="lang-tabs">
                <div class="lang-tab active" data-lang="en">🇬🇧 English</div>
                <div class="lang-tab" data-lang="id">🇮🇩 Indonesia</div>
            </div>

            <!-- English EULA -->
            <div class="eula-pane active" id="pane-en">
                <div class="eula-box" id="eula-en">
                    <h2>END USER LICENSE AGREEMENT (EULA)</h2>
                    <p><strong>NEXUS QUANTUM TECH</strong> — Product: Nexus Quantum Rust Platform</p>
                    <p>This End User License Agreement ("Agreement") is a legal agreement between the User and Nexus Quantum Tech as the technology owner and copyright holder of the software branded Nexus Quantum Rust ("Software"). By installing, accessing, or using this Software, the User is deemed to have read, understood, and agreed to all terms of this Agreement. If the User does not agree to these terms, the installation and use of the Software must be discontinued immediately.</p>

                    <h2>Article 1 – Intellectual Property Rights</h2>
                    <p>All copyrights, patents, trade secrets, algorithms, source code, object code, analytic engines, AI models, system designs, documentation, and all components of the Software are the exclusive property of Nexus Quantum Tech. This Agreement does not grant ownership rights to the User, but only a limited right of use.</p>

                    <h2>Article 2 – License Grant</h2>
                    <p>Nexus Quantum Tech grants the User a limited, non-exclusive, non-transferable, and non-sublicensable license to use the Software according to the number of licenses granted. This license is not a sale of the product.</p>

                    <h2>Article 3 – Installation and Activation Restrictions</h2>
                    <p>The Software may only be installed according to the number of valid licenses. Protection mechanisms may include: license activation, machine fingerprinting, hardware binding, license keys, online validation, or other mechanisms. Installation beyond the number of valid licenses is considered a violation.</p>

                    <h2>Article 4 – Prohibition on Piracy and Modification</h2>
                    <p>The User is prohibited from: duplicating the Software, distributing the installer, reselling the Software, performing reverse engineering or decompilation, modifying the Software, removing license protections, or creating derivative versions without permission.</p>

                    <h2>Article 5 – Right to Audit Usage</h2>
                    <p>Nexus Quantum Tech reserves the right to audit Software usage to ensure license compliance through validation, usage reports, or other technical mechanisms. The User is required to cooperate.</p>

                    <h2>Article 6 – Telemetry and System Validation</h2>
                    <p>The Software may transmit limited technical data for license validation (license status, device identification, number of installations, Software version, error data). The User's business operational data will not be transmitted without permission.</p>

                    <h2>Article 7 – User Obligations</h2>
                    <p>The User is obliged to: use the Software lawfully, maintain the confidentiality of the license, not misuse the Software, and comply with Nexus Quantum Tech's provisions.</p>

                    <h2>Article 8 – Violations and Penalties</h2>
                    <p>In the event of a license violation, Nexus Quantum Tech reserves the right to: deactivate the license, terminate usage, block activation, claim damages, or take legal action.</p>

                    <h2>Article 9 – Software Updates</h2>
                    <p>The Software may receive automatic or manual updates for security improvements, features, and system stability.</p>

                    <h2>Article 10 – Limitation of Liability</h2>
                    <p>The Software is provided on an "AS IS" basis. Nexus Quantum Tech is not liable for business losses, data loss, or operational disruptions. The User is responsible for data backups.</p>

                    <h2>Article 11 – Termination of License</h2>
                    <p>The license may be terminated if a violation occurs or if the license expires. The User must cease use and remove the Software upon termination.</p>

                    <h2>Article 12 – Governing Law</h2>
                    <p>This Agreement is subject to the laws of the Republic of Indonesia.</p>

                    <h2>Article 13 – Entire Agreement</h2>
                    <p>This Agreement constitutes the entire agreement between the User and Nexus Quantum Tech regarding the use of the Software.</p>

                    <h2>Article 14 – Prohibition on Unauthorized Service Provision and Sales</h2>
                    <ul>
                        <li>The Software is licensed solely for the User's internal use.</li>
                        <li>The User is prohibited from using the Software to provide services to third parties (SaaS, analytics, data processing, cloud, managed services, outsourcing, consulting, or other digital services).</li>
                        <li>Commercializing services built on the Software requires written approval from Nexus Quantum Tech.</li>
                        <li>Violation constitutes a material breach granting Nexus Quantum Tech the right to terminate the license and claim damages.</li>
                    </ul>

                    <h2>Article 15 – Prohibition on License Sharing</h2>
                    <p>Each license is granted specifically to the registered entity or device. Sharing license keys, using one license across multiple devices or servers, or alternating use to avoid purchasing additional licenses is a material breach. Nexus Quantum Tech reserves the right to deactivate licenses detected as being used unauthorizedly.</p>

                    <h2>Article 16 – Prohibition on Activation Bypass</h2>
                    <p>The User is prohibited from avoiding, disabling, or bypassing license protection mechanisms (using cracks, patches, license generators, modifying system files, manipulating device identity, using emulators, or removing verification mechanisms). Any bypass attempt is considered a serious violation.</p>

                    <h2>Article 17 – Automated Audit and Validation</h2>
                    <p>The Software may perform automatic verification and usage audits to ensure license compliance. Audits are strictly for license compliance, not to retrieve business data. The User agrees to the automated audit mechanism.</p>

                    <h2>Article 18 – Prohibition on Disassembly, Analysis, and Code Rewriting</h2>
                    <p>The User is prohibited from disassembling, analyzing, or disclosing the internal structure of the Software, or creating software with substantially similar functions, structure, or architecture. All algorithms and architectural designs are considered trade secrets of Nexus Quantum Tech.</p>

                    <h2>Article 19 – Protection of AI and Analytics Engine</h2>
                    <p>All AI technology, analytic engines, ML models, and data processing algorithms are intellectual property and trade secrets of Nexus Quantum Tech. The User is prohibited from extracting, copying, or reconstructing AI models or analytic engines.</p>

                    <h2>Article 20 – Restrictions on Output Usage and Competitor Model Protection</h2>
                    <p>The User is prohibited from using Software outputs to train or develop AI systems or analytic models, or for benchmarking aimed at developing competing products, without written approval.</p>

                    <h2>Article 21 – Right to Inspect Algorithm and System Module Usage</h2>
                    <p>Nexus Quantum Tech may inspect usage of modules, algorithms, and main functions to ensure license compliance without accessing the User's sensitive business data.</p>

                    <h2>Article 22 – Right to Remote Restriction or Deactivation</h2>
                    <p>Nexus Quantum Tech reserves the right to restrict, deactivate, or terminate Software access remotely if violations are detected. Nexus Quantum Tech is not liable for losses arising from deactivation actions taken based on User violations.</p>

                    <h2>Article 23 – Prohibition on Developing Competitor Models or Products</h2>
                    <p>The User is prohibited from using the Software to develop competing products, systems, or services. This provision remains in effect even after the license has expired.</p>

                    <h2>Article 24 – Automatic Penalties for License Violations</h2>
                    <p>Each use without a valid license or exceeding granted licenses is a material breach. For each violation, the User must pay a penalty calculated based on the official license value. This does not waive the obligation to purchase official licenses.</p>

                    <h2>Article 25 – Calculation of Damages for Illegal Installations</h2>
                    <p>Each installation without a valid license is a separate violation. Damages are calculated based on the number of illegal installations multiplied by the official license price per installation, plus audit and enforcement costs.</p>

                    <h2>Article 26 – Right of Action Against Infrastructure Used for Piracy</h2>
                    <p>Nexus Quantum Tech reserves the right to take legal action against parties using the Software illegally on servers or infrastructure, and may cooperate with infrastructure providers to stop illegal use.</p>

                    <h2>Article 27 – Protection of Cloud Deployment and Virtual Environments</h2>
                    <p>Use in cloud environments, VMs, or containers remains subject to license terms. Each virtual instance or container running the Software counts as a separate license installation unless otherwise specified.</p>

                    <h2>Article 28 – License Control in Data Center and Large-Scale Environments</h2>
                    <p>Each server, computing node, or processing instance requires a valid license. The User is prohibited from using load balancing, clustering, or orchestration mechanisms to avoid license obligations.</p>
                </div>
            </div>

            <!-- Indonesian EULA -->
            <div class="eula-pane" id="pane-id">
                <div class="eula-box" id="eula-id">
                    <h2>PERJANJIAN LISENSI PENGGUNA AKHIR (EULA)</h2>
                    <p><strong>NEXUS QUANTUM TECH</strong> — Produk: Nexus Quantum Rust Platform</p>
                    <p>Perjanjian Lisensi Pengguna Akhir ini ("Perjanjian") merupakan perjanjian hukum antara Pengguna dan Nexus Quantum Tech sebagai pemilik teknologi dan pemegang hak cipta perangkat lunak bermerek Nexus Quantum Rust ("Software"). Dengan menginstal, mengakses, atau menggunakan Software ini, Pengguna dianggap telah membaca, memahami, dan menyetujui seluruh ketentuan perjanjian ini. Apabila Pengguna tidak menyetujui ketentuan ini, instalasi dan penggunaan Software harus dihentikan.</p>

                    <h2>Pasal 1 – Kepemilikan Hak Kekayaan Intelektual</h2>
                    <p>Seluruh hak cipta, hak paten, rahasia dagang, algoritma, source code, object code, engine analitik, model AI, desain sistem, dokumentasi, serta seluruh komponen Software merupakan hak milik eksklusif Nexus Quantum Tech. Perjanjian ini tidak memberikan hak kepemilikan kepada Pengguna atas Software, melainkan hanya hak penggunaan terbatas.</p>

                    <h2>Pasal 2 – Pemberian Lisensi</h2>
                    <p>Nexus Quantum Tech memberikan kepada Pengguna lisensi terbatas, non-eksklusif, tidak dapat dipindahtangankan, dan tidak dapat disublisensikan untuk menggunakan Software sesuai jumlah lisensi yang diberikan. Lisensi ini bukan penjualan produk.</p>

                    <h2>Pasal 3 – Pembatasan Instalasi dan Aktivasi</h2>
                    <p>Software hanya dapat diinstal sesuai jumlah lisensi yang sah. Software dapat menggunakan mekanisme proteksi seperti: aktivasi lisensi, machine fingerprint, hardware binding, license key, validasi online, atau mekanisme proteksi lainnya. Instalasi di luar jumlah lisensi dianggap pelanggaran.</p>

                    <h2>Pasal 4 – Larangan Pembajakan dan Modifikasi</h2>
                    <p>Pengguna dilarang: menggandakan Software, menyebarluaskan installer, menjual kembali Software, melakukan reverse engineering atau dekompilasi, memodifikasi Software, menghilangkan proteksi lisensi, atau membuat versi turunan tanpa izin.</p>

                    <h2>Pasal 5 – Hak Audit Penggunaan</h2>
                    <p>Nexus Quantum Tech berhak melakukan audit penggunaan Software untuk memastikan kepatuhan lisensi melalui validasi lisensi, laporan penggunaan, atau mekanisme teknis lainnya. Pengguna wajib bekerja sama dalam proses audit.</p>

                    <h2>Pasal 6 – Telemetry dan Validasi Sistem</h2>
                    <p>Software dapat mengirimkan data teknis terbatas untuk validasi lisensi (status lisensi, identifikasi perangkat, jumlah instalasi, versi Software, data teknis error). Data operasional bisnis Pengguna tidak dikirim tanpa izin.</p>

                    <h2>Pasal 7 – Kewajiban Pengguna</h2>
                    <p>Pengguna wajib: menggunakan Software secara sah, menjaga kerahasiaan lisensi, tidak menyalahgunakan Software, dan mematuhi ketentuan Nexus Quantum Tech.</p>

                    <h2>Pasal 8 – Pelanggaran dan Sanksi</h2>
                    <p>Apabila terjadi pelanggaran lisensi, Nexus Quantum Tech berhak: menonaktifkan lisensi, menghentikan penggunaan, memblokir aktivasi, menuntut ganti rugi, atau mengambil tindakan hukum.</p>

                    <h2>Pasal 9 – Pembaruan Software</h2>
                    <p>Software dapat menerima pembaruan otomatis atau manual untuk peningkatan keamanan, fitur, dan stabilitas sistem.</p>

                    <h2>Pasal 10 – Batasan Tanggung Jawab</h2>
                    <p>Software diberikan dalam kondisi "sebagaimana adanya". Nexus Quantum Tech tidak bertanggung jawab atas kerugian bisnis, kehilangan data, atau gangguan operasional. Pengguna bertanggung jawab melakukan backup data.</p>

                    <h2>Pasal 11 – Penghentian Lisensi</h2>
                    <p>Lisensi dapat dihentikan apabila terjadi pelanggaran atau lisensi berakhir. Pengguna wajib menghentikan penggunaan dan menghapus Software setelah penghentian.</p>

                    <h2>Pasal 12 – Hukum yang Berlaku</h2>
                    <p>Perjanjian ini tunduk pada hukum Republik Indonesia.</p>

                    <h2>Pasal 13 – Kesepakatan Penuh</h2>
                    <p>Perjanjian ini merupakan keseluruhan kesepakatan antara Pengguna dan Nexus Quantum Tech terkait penggunaan Software.</p>

                    <h2>Pasal 14 – Larangan Penyediaan dan Penjualan Layanan Berbasis Software Tanpa Izin</h2>
                    <ul>
                        <li>Software hanya dilisensikan untuk penggunaan internal Pengguna.</li>
                        <li>Pengguna dilarang menggunakan Software untuk menyediakan layanan kepada pihak ketiga (SaaS, analitik, pemrosesan data, cloud service, managed service, outsourcing, konsultasi berbasis sistem, atau layanan digital lainnya).</li>
                        <li>Pengguna yang ingin menyediakan layanan berbasis Software wajib memperoleh lisensi komersial atau perjanjian kemitraan resmi.</li>
                        <li>Pelanggaran merupakan pelanggaran material yang memberikan hak kepada Nexus Quantum Tech untuk menghentikan lisensi dan menuntut ganti rugi.</li>
                    </ul>

                    <h2>Pasal 15 – Larangan Berbagi Lisensi</h2>
                    <p>Setiap lisensi diberikan secara spesifik kepada entitas atau perangkat yang didaftarkan. Berbagi license key, menggunakan satu lisensi untuk beberapa perangkat atau server, atau penggunaan bergantian untuk menghindari pembelian lisensi tambahan adalah pelanggaran material. Nexus Quantum Tech berhak menonaktifkan lisensi yang terdeteksi digunakan secara tidak sah.</p>

                    <h2>Pasal 16 – Larangan Penghindaran atau Pembobolan Aktivasi Lisensi</h2>
                    <p>Pengguna dilarang menghindari, menonaktifkan, atau membobol mekanisme proteksi lisensi (menggunakan crack, patch, atau license generator; memodifikasi file sistem; memanipulasi identitas perangkat; menggunakan emulator; atau menghapus mekanisme verifikasi). Setiap upaya bypass adalah pelanggaran serius.</p>

                    <h2>Pasal 17 – Audit dan Validasi Penggunaan Secara Otomatis</h2>
                    <p>Software dapat melakukan verifikasi dan audit penggunaan secara otomatis untuk memastikan kepatuhan lisensi, secara terbatas tanpa mengambil data operasional bisnis. Pengguna menyetujui mekanisme audit otomatis.</p>

                    <h2>Pasal 18 – Larangan Pembongkaran, Analisis, dan Penulisan Ulang Kode</h2>
                    <p>Pengguna dilarang melakukan pembongkaran, analisis, atau pengungkapan struktur internal Software, atau membuat perangkat lunak dengan fungsi, struktur, atau arsitektur yang secara substansial sama. Setiap algoritma dan desain arsitektur dianggap rahasia dagang Nexus Quantum Tech.</p>

                    <h2>Pasal 19 – Perlindungan Engine AI dan Analitik</h2>
                    <p>Seluruh teknologi AI, engine analitik, model machine learning, dan algoritma pemrosesan data merupakan kekayaan intelektual dan rahasia dagang Nexus Quantum Tech. Pengguna dilarang mengambil, menyalin, atau merekonstruksi model AI atau engine analitik.</p>

                    <h2>Pasal 20 – Pembatasan Penggunaan Output dan Perlindungan terhadap Model Kompetitor</h2>
                    <p>Pengguna dilarang menggunakan output Software untuk melatih atau mengembangkan sistem AI atau model analitik, atau untuk benchmarking yang ditujukan mengembangkan produk pesaing, tanpa persetujuan tertulis.</p>

                    <h2>Pasal 21 – Hak Inspeksi Penggunaan Algoritma dan Modul Sistem</h2>
                    <p>Nexus Quantum Tech berhak melakukan pemeriksaan penggunaan modul, algoritma, dan fungsi utama Software untuk memastikan kepatuhan lisensi tanpa mengakses data bisnis sensitif.</p>

                    <h2>Pasal 22 – Hak Pembatasan atau Penonaktifan Software Secara Jarak Jauh</h2>
                    <p>Nexus Quantum Tech berhak membatasi fungsi, menonaktifkan lisensi, atau menghentikan akses Software secara jarak jauh apabila terdeteksi pelanggaran. Nexus Quantum Tech tidak bertanggung jawab atas kerugian akibat penonaktifan yang dilakukan berdasarkan pelanggaran Pengguna.</p>

                    <h2>Pasal 23 – Larangan Pengembangan Model atau Produk Kompetitor</h2>
                    <p>Pengguna dilarang menggunakan Software sebagai dasar, referensi, atau sarana untuk mengembangkan produk, sistem, atau layanan yang bersaing dengan Software. Ketentuan ini tetap berlaku meskipun lisensi telah berakhir.</p>

                    <h2>Pasal 24 – Penalti Otomatis atas Pelanggaran Lisensi</h2>
                    <p>Setiap penggunaan Software tanpa lisensi sah atau melebihi jumlah lisensi dianggap pelanggaran material. Atas setiap pelanggaran, Pengguna wajib membayar penalti berdasarkan nilai lisensi resmi. Penalti tidak menghapus kewajiban membeli lisensi resmi.</p>

                    <h2>Pasal 25 – Perhitungan Ganti Rugi atas Instalasi Ilegal</h2>
                    <p>Setiap instalasi tanpa lisensi sah adalah pelanggaran terpisah. Ganti rugi dihitung berdasarkan jumlah instalasi ilegal dikali harga lisensi resmi per instalasi, ditambah biaya audit dan penegakan kepatuhan.</p>

                    <h2>Pasal 26 – Hak Tindakan terhadap Infrastruktur yang Digunakan untuk Pembajakan</h2>
                    <p>Nexus Quantum Tech berhak mengambil tindakan hukum terhadap pihak yang menggunakan Software secara ilegal pada server atau infrastruktur tertentu, dan dapat bekerja sama dengan penyedia infrastruktur untuk menghentikan penggunaan ilegal.</p>

                    <h2>Pasal 27 – Perlindungan Deployment Cloud dan Lingkungan Virtual</h2>
                    <p>Penggunaan Software pada lingkungan cloud, VM, atau container tetap tunduk pada ketentuan lisensi. Setiap instansi virtual atau container yang menjalankan Software dihitung sebagai instalasi lisensi terpisah kecuali ditentukan lain.</p>

                    <h2>Pasal 28 – Kontrol Lisensi pada Lingkungan Pusat Data dan Skala Besar</h2>
                    <p>Setiap server, node komputasi, atau instansi pemrosesan memerlukan lisensi yang sah. Pengguna dilarang menggunakan mekanisme load balancing, clustering, atau orkestrasi sistem untuk menghindari kewajiban lisensi.</p>
                </div>
            </div>

            <!-- Scroll hint – visibility:hidden keeps the space -->
            <p class="scroll-hint" id="scroll-hint">↓ Scroll down to read the full agreement</p>

            <!-- Agree checkbox -->
            <div id="agree-row">
                <input type="checkbox" id="agree-checkbox" disabled>
                <label id="agree-label" for="agree-checkbox">
                    I have read, understood, and agree to the End User License Agreement (EULA) of Nexus Quantum Tech.<br>
                    <span style="font-size:12px;color:#aaa;">Saya telah membaca, memahami, dan menyetujui Perjanjian Lisensi Pengguna Akhir (EULA) Nexus Quantum Tech.</span>
                </label>
            </div>

            <!-- License key form (revealed after agreement) -->
            <div id="license-form-section">
                <form id="kc-license-form" class="${properties.kcFormClass!}" action="" method="post">
                    <div class="${properties.kcFormGroupClass!}">
                        <label class="nq-label" for="licenseKey">License Key</label>
                        <div class="nq-input-wrap">
                            <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/>
                            </svg>
                            <input id="licenseKey" class="nq-input" name="licenseKey" type="text"
                                   autofocus autocomplete="off" placeholder="XXXX-XXXX-XXXX-XXXX"/>
                        </div>
                    </div>
                    <button class="nq-btn" name="activate" id="kc-activate" type="submit">Activate License</button>
                </form>

                <div class="nq-divider">or</div>

                <div class="nq-upload" id="file-upload-zone">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#FF6B35" stroke-width="2">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/>
                    </svg>
                    <div class="nq-upload-title">Click or drag .lic file to upload</div>
                    <div class="nq-upload-sub">For offline or air-gapped deployments</div>
                    <input type="file" id="licenseFile" style="display:none;" accept=".lic"/>
                </div>
            </div>
        </div>

        <script>
        (function () {
            var unlocked = false;

            /* ── Tab switching ── */
            document.querySelectorAll('.lang-tab').forEach(function (tab) {
                tab.addEventListener('click', function () {
                    document.querySelectorAll('.lang-tab').forEach(function (t) { t.classList.remove('active'); });
                    document.querySelectorAll('.eula-pane').forEach(function (p) { p.classList.remove('active'); });
                    tab.classList.add('active');
                    document.getElementById('pane-' + tab.dataset.lang).classList.add('active');
                    updateHint();
                });
            });

            /* ── Scroll detection for both boxes ── */
            function onScroll() {
                if (unlocked) return;
                var activePane = document.querySelector('.eula-pane.active');
                var box = activePane ? activePane.querySelector('.eula-box') : null;
                if (!box) return;
                var remaining = box.scrollHeight - box.scrollTop - box.clientHeight;
                if (remaining < 40) {
                    unlocked = true;
                    var cb = document.getElementById('agree-checkbox');
                    cb.disabled = false;
                    document.getElementById('agree-row').classList.add('enabled');
                    document.getElementById('scroll-hint').classList.add('done');
                }
            }

            function updateHint() {
                if (unlocked) return;
                /* Reset hint visibility when switching tabs before unlocked */
                document.getElementById('scroll-hint').classList.remove('done');
            }

            document.getElementById('eula-en').addEventListener('scroll', onScroll);
            document.getElementById('eula-id').addEventListener('scroll', onScroll);

            /* ── Checkbox reveal form ── */
            document.getElementById('agree-checkbox').addEventListener('change', function () {
                var fs = document.getElementById('license-form-section');
                if (this.checked) {
                    fs.classList.add('visible');
                    setTimeout(function () { fs.scrollIntoView({ behavior: 'smooth', block: 'start' }); }, 50);
                } else {
                    fs.classList.remove('visible');
                }
            });

            /* ── File upload ── */
            document.getElementById('file-upload-zone').addEventListener('click', function () {
                document.getElementById('licenseFile').click();
            });
            function applyFile(file) {
                if (!file) return;
                var reader = new FileReader();
                reader.onload = function (ev) {
                    var inp = document.getElementById('licenseKey');
                    if (inp) { inp.value = ev.target.result.trim(); inp.focus(); }
                };
                reader.readAsText(file);
            }
            document.getElementById('licenseFile').addEventListener('change', function (e) { applyFile(e.target.files[0]); });
            var zone = document.getElementById('file-upload-zone');
            zone.addEventListener('dragover',  function (e) { e.preventDefault(); zone.style.background='#ffeee6'; });
            zone.addEventListener('dragleave', function ()   { zone.style.background='#fff9f6'; });
            zone.addEventListener('drop',      function (e)  { e.preventDefault(); zone.style.background='#fff9f6'; applyFile(e.dataTransfer.files[0]); });
        })();
        </script>
    </#if>
</@layout.registrationLayout>
