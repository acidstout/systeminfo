;@Ahk2Exe-SetName SystemInfo
;@Ahk2Exe-SetProductName System Information Viewer
;@Ahk2Exe-SetDescription Comprehensive hardware & software report with export
;@Ahk2Exe-SetCompanyName Rekow IT
;@Ahk2Exe-SetCopyright Copyright © 2026 Rekow IT
;@Ahk2Exe-SetVersion 1.3
;@Ahk2Exe-SetLanguage 0x0807
#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon
SetWorkingDir(A_ScriptDir)

; ─── Global state ───────────────────────────────────────────────
global APP_VERSION   := "1.3.0"
global APP_COPYRIGHT := "`n`nCopyright © 2026 by Rekow IT`n`nhttps://rekow.ch"
global GITHUB_REPO   := "acidstout/systeminfo"
global AllData       := Map()
global GuiCtx        := {}
global Lang          := ""
global Strings       := Map()
global WmiCimv2      := ""
global WmiRootWmi    := ""
global SharedOSData  := ""

; ─── Detect language and initialize strings ─────────────────────
InitLanguage()

; ─── Show GUI immediately, then load data ───────────────────────
BuildMainWindow()
ScheduleDataLoad()
return

; ═══════════════════════════════════════════════════════════════
;  LOCALIZATION
; ═══════════════════════════════════════════════════════════════

InitLanguage() {
    global Lang, Strings

    ; Detect system UI language (LANGID)
    ; German: 0x0407 (DE), 0x0807 (AT), 0x0C07 (CH), 0x1007 (LU), 0x1407 (LI)
    ; Primary language ID for German = 0x07
    langId := DllCall("GetUserDefaultUILanguage", "UShort")
    primaryLang := langId & 0x3FF
    Lang := (primaryLang = 0x07) ? "de" : "en"

    if (Lang = "de")
        InitGerman()
    else
        InitEnglish()
}

InitEnglish() {
    global Strings
    ; ─── Window / chrome ────────────────────────────────────────
    Strings["win_title"]          := "SystemInfo — Hardware & Software Report"
    Strings["header"]             := "⬢  System Information Report"
    Strings["generated"]          := "Generated"
    Strings["btn_export"]         := "💾  Export to File"
    Strings["btn_clipboard"]      := "📋  Copy to Clipboard"
    Strings["btn_refresh"]        := "🔄  Refresh Data"
    Strings["btn_about"]          := "ℹ  About"
    Strings["btn_update"]         := "⬆  Update"
    Strings["about_text"]         := "SystemInfo v" . APP_VERSION . "`n`nComprehensive system information viewer" . APP_COPYRIGHT
    Strings["about_title"]        := "About SystemInfo"
    Strings["upd_checking"]       := "Checking for updates…"
    Strings["upd_available"]      := "Update available!"
    Strings["upd_current"]        := "Current version"
    Strings["upd_latest"]         := "Latest version"
    Strings["upd_confirm"]        := "Do you want to download and install the update?`nThe application will restart automatically."
    Strings["upd_downloading"]    := "Downloading update…"
    Strings["upd_success"]        := "Update installed successfully!`nThe application will now restart."
    Strings["upd_success_title"]  := "Update Complete"
    Strings["upd_noupdate"]       := "You are running the latest version ({1})."
    Strings["upd_noupdate_title"] := "No Update Available"
    Strings["upd_error"]          := "Update check failed:"
    Strings["upd_error_title"]    := "Update Error"
    Strings["upd_dl_error"]       := "Download failed:"
    Strings["upd_dl_error_title"] := "Download Error"
    Strings["sb_starting"]        := "  ⏳  Starting up…"
    Strings["sb_collecting"]      := "  ⏳  Collecting system information…"
    Strings["sb_done"]            := "  ✓  {1} properties collected across {2} categories     |     {3}"
    Strings["sb_refreshing"]      := "  🔄  Refreshing system information…"
    Strings["sb_refreshed"]       := "  ✓  {1} properties refreshed at {2}     |     {3}"
    Strings["admin_yes"]          := "Running as Administrator"
    Strings["admin_tip"]          := "Tip: Run as Admin for full detail"
    Strings["loading"]            := "  ⏳  Loading…"
    Strings["loading_detail"]     := "Please wait, querying hardware information"
    Strings["refreshing"]         := "  🔄  Refreshing…"
    Strings["refreshing_detail"]  := "Re-querying hardware information"
    Strings["export_dialog"]      := "Export System Report"
    Strings["export_filter"]      := "Text Files (*.txt)"
    Strings["export_ok"]          := "Report saved successfully:"
    Strings["export_ok_title"]    := "Export Complete"
    Strings["export_err"]         := "Failed to save report:"
    Strings["export_err_title"]   := "Export Error"
    Strings["clipboard_ok"]       := "✓  Report copied to clipboard!"
    Strings["report_title"]       := "SYSTEM INFORMATION REPORT"
    Strings["report_end"]         := "End of Report"
    Strings["col_property"]       := "Property"
    Strings["col_value"]          := "Value"

    ; ─── Tab names ──────────────────────────────────────────────
    Strings["tab_os"]             := "🖥 OS && System"
    Strings["tab_cpu"]            := "⚙ CPU"
    Strings["tab_memory"]         := "🧩 Memory"
    Strings["tab_gpu"]            := "🎮 GPU && Display"
    Strings["tab_disks"]          := "💾 Disks"
    Strings["tab_network"]        := "🌐 Network"
    Strings["tab_mainboard"]      := "🔧 Mainboard"
    Strings["tab_audio"]          := "🔊 Audio"

    ; ─── Section headings (export) ──────────────────────────────
    Strings["sec_os"]             := "OPERATING SYSTEM && COMPUTER"
    Strings["sec_cpu"]            := "PROCESSOR (CPU)"
    Strings["sec_memory"]         := "MEMORY (RAM)"
    Strings["sec_gpu"]            := "GRAPHICS && DISPLAY"
    Strings["sec_disks"]          := "STORAGE (DISKS)"
    Strings["sec_network"]        := "NETWORK ADAPTERS"
    Strings["sec_mainboard"]      := "MAINBOARD && BIOS"
    Strings["sec_audio"]          := "AUDIO DEVICES"

    ; ─── Data labels: OS ────────────────────────────────────────
    Strings["os_name"]            := "OS Name"
    Strings["os_version"]         := "Version"
    Strings["os_build"]           := "Build"
    Strings["os_arch"]            := "Architecture"
    Strings["os_install"]         := "Install Date"
    Strings["os_boot"]            := "Last Boot"
    Strings["os_sysdir"]          := "System Directory"
    Strings["os_windir"]          := "Windows Directory"
    Strings["os_user_reg"]        := "Registered User"
    Strings["os_serial"]          := "Serial Number"
    Strings["os_uptime"]          := "Uptime"
    Strings["os_hostname"]        := "Computer Name"
    Strings["os_domain"]          := "Domain"
    Strings["os_manufacturer"]    := "Manufacturer"
    Strings["os_model"]           := "Model"
    Strings["os_systype"]         := "System Type"
    Strings["os_totalram"]        := "Total Physical RAM"
    Strings["os_timezone"]        := "Time Zone"
    Strings["os_curuser"]         := "Current User"
    Strings["os_locale"]          := "Locale"

    ; ─── Data labels: CPU ───────────────────────────────────────
    Strings["cpu_name"]           := "Name"
    Strings["cpu_mfg"]            := "Manufacturer"
    Strings["cpu_desc"]           := "Description"
    Strings["cpu_cores"]          := "Cores (Physical)"
    Strings["cpu_threads"]        := "Threads (Logical)"
    Strings["cpu_baseclock"]      := "Base Clock"
    Strings["cpu_curclock"]       := "Current Clock"
    Strings["cpu_l2"]             := "L2 Cache"
    Strings["cpu_l3"]             := "L3 Cache"
    Strings["cpu_socket"]         := "Socket"
    Strings["cpu_voltage"]        := "Voltage"
    Strings["cpu_status"]         := "Status"

    ; ─── Data labels: Memory ────────────────────────────────────
    Strings["mem_total"]          := "Total Physical"
    Strings["mem_used"]           := "Used"
    Strings["mem_avail"]          := "Available"
    Strings["mem_vtotal"]         := "Total Virtual"
    Strings["mem_vfree"]          := "Free Virtual"
    Strings["mem_dimm_hdr"]       := "─── DIMM Slots ───"
    Strings["mem_capacity"]       := "Capacity"
    Strings["mem_speed"]          := "Speed"
    Strings["mem_mfg"]            := "Manufacturer"
    Strings["mem_part"]           := "Part Number"
    Strings["mem_form"]           := "Form Factor"
    Strings["mem_type"]           := "Type"
    Strings["mem_bank"]           := "Bank/Locator"
    Strings["mem_admin"]          := "Requires Administrator privileges"

    ; ─── Data labels: GPU ───────────────────────────────────────
    Strings["gpu_name"]           := "Name"
    Strings["gpu_compat"]         := "Adapter Compatibility"
    Strings["gpu_driver"]         := "Driver Version"
    Strings["gpu_driverdate"]     := "Driver Date"
    Strings["gpu_vram"]           := "VRAM (reported)"
    Strings["gpu_vidmode"]        := "Video Mode"
    Strings["gpu_res"]            := "Resolution"
    Strings["gpu_refresh"]        := "Refresh Rate"
    Strings["gpu_bpp"]            := "Bits/Pixel"
    Strings["gpu_status"]         := "Status"
    Strings["gpu_pnp"]            := "PNP Device ID"
    Strings["mon_name"]           := "Monitor Name"
    Strings["mon_mfg"]            := "Manufacturer"
    Strings["mon_serial"]         := "Serial Number"
    Strings["mon_prodcode"]       := "Product Code"
    Strings["mon_res"]            := "Resolution"
    Strings["mon_refresh"]        := "Refresh Rate"
    Strings["mon_conn"]           := "Connection"
    Strings["mon_adapter"]        := "Adapter"
    Strings["mon_devid"]          := "Device ID"
    Strings["mon_none"]           := "No monitor data available"
    Strings["mon_primary"]        := "Primary"

    ; ─── Data labels: Disks ─────────────────────────────────────
    Strings["disk_model"]         := "Model"
    Strings["disk_iface"]         := "Interface"
    Strings["disk_serial"]        := "Serial Number"
    Strings["disk_fw"]            := "Firmware"
    Strings["disk_size"]          := "Size"
    Strings["disk_media"]         := "Media Type"
    Strings["disk_parts"]         := "Partitions"
    Strings["disk_status"]        := "Status"
    Strings["disk_vol_hdr"]       := "─── Logical Volumes ───"
    Strings["disk_fs"]            := "File System"
    Strings["disk_label"]         := "Label"
    Strings["disk_total"]         := "Total"
    Strings["disk_used"]          := "Used"
    Strings["disk_free"]          := "Free"
    Strings["disk_usage"]         := "Usage"
    Strings["disk_nolabel"]       := "(none)"

    ; ─── Data labels: Network ───────────────────────────────────
    Strings["net_desc"]           := "Description"
    Strings["net_mac"]            := "MAC Address"
    Strings["net_ip"]             := "IP Address(es)"
    Strings["net_subnet"]         := "Subnet(s)"
    Strings["net_gw"]             := "Gateway"
    Strings["net_dns"]            := "DNS Servers"
    Strings["net_dhcp"]           := "DHCP Enabled"
    Strings["net_dhcpsrv"]        := "DHCP Server"
    Strings["yes"]                := "Yes"
    Strings["no"]                 := "No"

    ; ─── Data labels: Mainboard ─────────────────────────────────
    Strings["mb_mfg"]             := "Board Manufacturer"
    Strings["mb_product"]         := "Board Product"
    Strings["mb_version"]         := "Board Version"
    Strings["mb_serial"]          := "Board Serial"
    Strings["bios_hdr"]           := "─── BIOS ───"
    Strings["bios_mfg"]           := "BIOS Manufacturer"
    Strings["bios_ver"]           := "BIOS Version"
    Strings["bios_date"]          := "BIOS Release Date"
    Strings["bios_smbios"]        := "SMBIOS Version"
    Strings["bios_serial"]        := "BIOS Serial"
    Strings["tpm_hdr"]            := "─── Trusted Platform Module ───"
    Strings["tpm_present"]        := "TPM Present"
    Strings["tpm_mfg"]            := "TPM Manufacturer"
    Strings["tpm_ver"]            := "TPM Version"
    Strings["tpm_no"]             := "Not detected"
    Strings["tpm_admin"]          := "Query requires Admin privileges"

    ; ─── Data labels: Audio ─────────────────────────────────────
    Strings["audio_name"]         := "Name"
    Strings["audio_mfg"]          := "Manufacturer"
    Strings["audio_status"]       := "Status"
    Strings["audio_pnp"]          := "PNP Device ID"
    Strings["audio_none"]         := "No devices found"

    ; ─── Data labels: Printers ──────────────────────────────────
    Strings["tab_printers"]       := "🖨 Printers"
    Strings["sec_printers"]       := "PRINTERS"
    Strings["prn_name"]           := "Name"
    Strings["prn_driver"]         := "Driver"
    Strings["prn_port"]           := "Port"
    Strings["prn_default"]        := "Default Printer"
    Strings["prn_shared"]         := "Shared"
    Strings["prn_sharename"]      := "Share Name"
    Strings["prn_network"]        := "Network Printer"
    Strings["prn_status"]         := "Status"
    Strings["prn_location"]       := "Location"
    Strings["prn_duplex"]         := "Duplex"
    Strings["prn_color"]          := "Color"
    Strings["prn_horizontal"]     := "Horizontal Resolution"
    Strings["prn_vertical"]       := "Vertical Resolution"
    Strings["prn_none"]           := "No printers found"

    ; ─── Data labels: Peripherals ───────────────────────────────
    Strings["tab_peripherals"]    := "🔌 Peripherals"
    Strings["sec_peripherals"]    := "PERIPHERALS && USB DEVICES"
    Strings["per_usb_hdr"]        := "─── USB Controllers ───"
    Strings["per_usb_name"]       := "Name"
    Strings["per_usb_mfg"]        := "Manufacturer"
    Strings["per_usb_devid"]      := "Device ID"
    Strings["per_usb_status"]     := "Status"
    Strings["per_usbdev_hdr"]     := "─── USB Devices ───"
    Strings["per_input_hdr"]      := "─── Input Devices ───"
    Strings["per_input_name"]     := "Name"
    Strings["per_input_desc"]     := "Description"
    Strings["per_input_devid"]    := "Device ID"
    Strings["per_input_status"]   := "Status"
    Strings["per_cam_hdr"]        := "─── Cameras && Imaging ───"
    Strings["per_cam_name"]       := "Name"
    Strings["per_cam_mfg"]        := "Manufacturer"
    Strings["per_cam_status"]     := "Status"
    Strings["per_bt_hdr"]         := "─── Bluetooth ───"
    Strings["per_bt_name"]        := "Name"
    Strings["per_bt_mfg"]         := "Manufacturer"
    Strings["per_bt_status"]      := "Status"
    Strings["per_none"]           := "No peripheral devices found"
}

InitGerman() {
    global Strings
    ; ─── Fenster / Oberfläche ───────────────────────────────────
    Strings["win_title"]          := "SystemInfo — Hardware- & Software-Bericht"
    Strings["header"]             := "⬢  Systeminformationsbericht"
    Strings["generated"]          := "Erstellt"
    Strings["btn_export"]         := "💾  Als Datei speichern"
    Strings["btn_clipboard"]      := "📋  In Zwischenablage"
    Strings["btn_refresh"]        := "🔄  Aktualisieren"
    Strings["btn_about"]          := "ℹ  Info"
    Strings["btn_update"]         := "⬆  Update"
    Strings["about_text"]         := "SystemInfo v" . APP_VERSION . "`n`nUmfassende Systeminformationsanzeige" . APP_COPYRIGHT
    Strings["about_title"]        := "Über SystemInfo"
    Strings["upd_checking"]       := "Suche nach Updates…"
    Strings["upd_available"]      := "Update verfügbar!"
    Strings["upd_current"]        := "Aktuelle Version"
    Strings["upd_latest"]         := "Neueste Version"
    Strings["upd_confirm"]        := "Möchten Sie das Update herunterladen und installieren?`nDie Anwendung wird automatisch neu gestartet."
    Strings["upd_downloading"]    := "Update wird heruntergeladen…"
    Strings["upd_success"]        := "Update erfolgreich installiert!`nDie Anwendung wird jetzt neu gestartet."
    Strings["upd_success_title"]  := "Update abgeschlossen"
    Strings["upd_noupdate"]       := "Sie verwenden bereits die neueste Version ({1})."
    Strings["upd_noupdate_title"] := "Kein Update verfügbar"
    Strings["upd_error"]          := "Update-Prüfung fehlgeschlagen:"
    Strings["upd_error_title"]    := "Update-Fehler"
    Strings["upd_dl_error"]       := "Download fehlgeschlagen:"
    Strings["upd_dl_error_title"] := "Download-Fehler"
    Strings["sb_starting"]        := "  ⏳  Wird gestartet…"
    Strings["sb_collecting"]      := "  ⏳  Systeminformationen werden gesammelt…"
    Strings["sb_done"]            := "  ✓  {1} Eigenschaften in {2} Kategorien erfasst     |     {3}"
    Strings["sb_refreshing"]      := "  🔄  Systeminformationen werden aktualisiert…"
    Strings["sb_refreshed"]       := "  ✓  {1} Eigenschaften aktualisiert um {2}     |     {3}"
    Strings["admin_yes"]          := "Als Administrator ausgeführt"
    Strings["admin_tip"]          := "Tipp: Als Admin ausführen für vollständige Details"
    Strings["loading"]            := "  ⏳  Laden…"
    Strings["loading_detail"]     := "Bitte warten, Hardware wird abgefragt"
    Strings["refreshing"]         := "  🔄  Aktualisierung…"
    Strings["refreshing_detail"]  := "Hardware wird erneut abgefragt"
    Strings["export_dialog"]      := "Systembericht exportieren"
    Strings["export_filter"]      := "Textdateien (*.txt)"
    Strings["export_ok"]          := "Bericht erfolgreich gespeichert:"
    Strings["export_ok_title"]    := "Export abgeschlossen"
    Strings["export_err"]         := "Fehler beim Speichern:"
    Strings["export_err_title"]   := "Exportfehler"
    Strings["clipboard_ok"]       := "✓  Bericht in Zwischenablage kopiert!"
    Strings["report_title"]       := "SYSTEMINFORMATIONSBERICHT"
    Strings["report_end"]         := "Ende des Berichts"
    Strings["col_property"]       := "Eigenschaft"
    Strings["col_value"]          := "Wert"

    ; ─── Tab-Namen ──────────────────────────────────────────────
    Strings["tab_os"]             := "🖥 System"
    Strings["tab_cpu"]            := "⚙ Prozessor"
    Strings["tab_memory"]         := "🧩 Arbeitsspeicher"
    Strings["tab_gpu"]            := "🎮 Grafik && Anzeige"
    Strings["tab_disks"]          := "💾 Datenträger"
    Strings["tab_network"]        := "🌐 Netzwerk"
    Strings["tab_mainboard"]      := "🔧 Hauptplatine"
    Strings["tab_audio"]          := "🔊 Audio"

    ; ─── Abschnittsüberschriften (Export) ───────────────────────
    Strings["sec_os"]             := "BETRIEBSSYSTEM && COMPUTER"
    Strings["sec_cpu"]            := "PROZESSOR (CPU)"
    Strings["sec_memory"]         := "ARBEITSSPEICHER (RAM)"
    Strings["sec_gpu"]            := "GRAFIK && ANZEIGE"
    Strings["sec_disks"]          := "DATENTRÄGER"
    Strings["sec_network"]        := "NETZWERKADAPTER"
    Strings["sec_mainboard"]      := "HAUPTPLATINE && BIOS"
    Strings["sec_audio"]          := "AUDIOGERÄTE"

    ; ─── Datenlabels: BS ────────────────────────────────────────
    Strings["os_name"]            := "Betriebssystem"
    Strings["os_version"]         := "Version"
    Strings["os_build"]           := "Build"
    Strings["os_arch"]            := "Architektur"
    Strings["os_install"]         := "Installationsdatum"
    Strings["os_boot"]            := "Letzter Start"
    Strings["os_sysdir"]          := "Systemverzeichnis"
    Strings["os_windir"]          := "Windows-Verzeichnis"
    Strings["os_user_reg"]        := "Registrierter Benutzer"
    Strings["os_serial"]          := "Seriennummer"
    Strings["os_uptime"]          := "Betriebszeit"
    Strings["os_hostname"]        := "Computername"
    Strings["os_domain"]          := "Domäne"
    Strings["os_manufacturer"]    := "Hersteller"
    Strings["os_model"]           := "Modell"
    Strings["os_systype"]         := "Systemtyp"
    Strings["os_totalram"]        := "Physischer RAM gesamt"
    Strings["os_timezone"]        := "Zeitzone"
    Strings["os_curuser"]         := "Aktueller Benutzer"
    Strings["os_locale"]          := "Gebietsschema"

    ; ─── Datenlabels: CPU ───────────────────────────────────────
    Strings["cpu_name"]           := "Bezeichnung"
    Strings["cpu_mfg"]            := "Hersteller"
    Strings["cpu_desc"]           := "Beschreibung"
    Strings["cpu_cores"]          := "Kerne (physisch)"
    Strings["cpu_threads"]        := "Threads (logisch)"
    Strings["cpu_baseclock"]      := "Basistakt"
    Strings["cpu_curclock"]       := "Aktueller Takt"
    Strings["cpu_l2"]             := "L2-Cache"
    Strings["cpu_l3"]             := "L3-Cache"
    Strings["cpu_socket"]         := "Sockel"
    Strings["cpu_voltage"]        := "Spannung"
    Strings["cpu_status"]         := "Status"

    ; ─── Datenlabels: Arbeitsspeicher ───────────────────────────
    Strings["mem_total"]          := "Physisch gesamt"
    Strings["mem_used"]           := "Belegt"
    Strings["mem_avail"]          := "Verfügbar"
    Strings["mem_vtotal"]         := "Virtuell gesamt"
    Strings["mem_vfree"]          := "Virtuell frei"
    Strings["mem_dimm_hdr"]       := "─── DIMM-Steckplätze ───"
    Strings["mem_capacity"]       := "Kapazität"
    Strings["mem_speed"]          := "Geschwindigkeit"
    Strings["mem_mfg"]            := "Hersteller"
    Strings["mem_part"]           := "Teilenummer"
    Strings["mem_form"]           := "Formfaktor"
    Strings["mem_type"]           := "Typ"
    Strings["mem_bank"]           := "Bank/Steckplatz"
    Strings["mem_admin"]          := "Erfordert Administratorrechte"

    ; ─── Datenlabels: Grafik ────────────────────────────────────
    Strings["gpu_name"]           := "Bezeichnung"
    Strings["gpu_compat"]         := "Adapterkompatibilität"
    Strings["gpu_driver"]         := "Treiberversion"
    Strings["gpu_driverdate"]     := "Treiberdatum"
    Strings["gpu_vram"]           := "VRAM (gemeldet)"
    Strings["gpu_vidmode"]        := "Videomodus"
    Strings["gpu_res"]            := "Auflösung"
    Strings["gpu_refresh"]        := "Bildwiederholrate"
    Strings["gpu_bpp"]            := "Bits/Pixel"
    Strings["gpu_status"]         := "Status"
    Strings["gpu_pnp"]            := "PNP-Geräte-ID"
    Strings["mon_name"]           := "Monitorname"
    Strings["mon_mfg"]            := "Hersteller"
    Strings["mon_serial"]         := "Seriennummer"
    Strings["mon_prodcode"]       := "Produktcode"
    Strings["mon_res"]            := "Auflösung"
    Strings["mon_refresh"]        := "Bildwiederholrate"
    Strings["mon_conn"]           := "Anschluss"
    Strings["mon_adapter"]        := "Adapter"
    Strings["mon_devid"]          := "Geräte-ID"
    Strings["mon_none"]           := "Keine Monitordaten verfügbar"
    Strings["mon_primary"]        := "Primär"

    ; ─── Datenlabels: Datenträger ───────────────────────────────
    Strings["disk_model"]         := "Modell"
    Strings["disk_iface"]         := "Schnittstelle"
    Strings["disk_serial"]        := "Seriennummer"
    Strings["disk_fw"]            := "Firmware"
    Strings["disk_size"]          := "Grösse"
    Strings["disk_media"]         := "Medientyp"
    Strings["disk_parts"]         := "Partitionen"
    Strings["disk_status"]        := "Status"
    Strings["disk_vol_hdr"]       := "─── Logische Laufwerke ───"
    Strings["disk_fs"]            := "Dateisystem"
    Strings["disk_label"]         := "Bezeichnung"
    Strings["disk_total"]         := "Gesamt"
    Strings["disk_used"]          := "Belegt"
    Strings["disk_free"]          := "Frei"
    Strings["disk_usage"]         := "Auslastung"
    Strings["disk_nolabel"]       := "(keine)"

    ; ─── Datenlabels: Netzwerk ──────────────────────────────────
    Strings["net_desc"]           := "Beschreibung"
    Strings["net_mac"]            := "MAC-Adresse"
    Strings["net_ip"]             := "IP-Adresse(n)"
    Strings["net_subnet"]         := "Subnetz(e)"
    Strings["net_gw"]             := "Gateway"
    Strings["net_dns"]            := "DNS-Server"
    Strings["net_dhcp"]           := "DHCP aktiviert"
    Strings["net_dhcpsrv"]        := "DHCP-Server"
    Strings["yes"]                := "Ja"
    Strings["no"]                 := "Nein"

    ; ─── Datenlabels: Hauptplatine ──────────────────────────────
    Strings["mb_mfg"]             := "Platinenhersteller"
    Strings["mb_product"]         := "Platinenprodukt"
    Strings["mb_version"]         := "Platinenversion"
    Strings["mb_serial"]          := "Platinen-Seriennr."
    Strings["bios_hdr"]           := "─── BIOS ───"
    Strings["bios_mfg"]           := "BIOS-Hersteller"
    Strings["bios_ver"]           := "BIOS-Version"
    Strings["bios_date"]          := "BIOS-Erscheinungsdatum"
    Strings["bios_smbios"]        := "SMBIOS-Version"
    Strings["bios_serial"]        := "BIOS-Seriennummer"
    Strings["tpm_hdr"]            := "─── Trusted Platform Module ───"
    Strings["tpm_present"]        := "TPM vorhanden"
    Strings["tpm_mfg"]            := "TPM-Hersteller"
    Strings["tpm_ver"]            := "TPM-Version"
    Strings["tpm_no"]             := "Nicht erkannt"
    Strings["tpm_admin"]          := "Abfrage erfordert Administratorrechte"

    ; ─── Datenlabels: Audio ─────────────────────────────────────
    Strings["audio_name"]         := "Bezeichnung"
    Strings["audio_mfg"]          := "Hersteller"
    Strings["audio_status"]       := "Status"
    Strings["audio_pnp"]          := "PNP-Geräte-ID"
    Strings["audio_none"]         := "Keine Geräte gefunden"

    ; ─── Datenlabels: Drucker ───────────────────────────────────
    Strings["tab_printers"]       := "🖨 Drucker"
    Strings["sec_printers"]       := "DRUCKER"
    Strings["prn_name"]           := "Name"
    Strings["prn_driver"]         := "Treiber"
    Strings["prn_port"]           := "Anschluss"
    Strings["prn_default"]        := "Standarddrucker"
    Strings["prn_shared"]         := "Freigegeben"
    Strings["prn_sharename"]      := "Freigabename"
    Strings["prn_network"]        := "Netzwerkdrucker"
    Strings["prn_status"]         := "Status"
    Strings["prn_location"]       := "Standort"
    Strings["prn_duplex"]         := "Duplex"
    Strings["prn_color"]          := "Farbe"
    Strings["prn_horizontal"]     := "Horizontale Auflösung"
    Strings["prn_vertical"]       := "Vertikale Auflösung"
    Strings["prn_none"]           := "Keine Drucker gefunden"

    ; ─── Datenlabels: Peripherie ────────────────────────────────
    Strings["tab_peripherals"]    := "🔌 Peripherie"
    Strings["sec_peripherals"]    := "PERIPHERIE && USB-GERÄTE"
    Strings["per_usb_hdr"]        := "─── USB-Controller ───"
    Strings["per_usb_name"]       := "Name"
    Strings["per_usb_mfg"]        := "Hersteller"
    Strings["per_usb_devid"]      := "Geräte-ID"
    Strings["per_usb_status"]     := "Status"
    Strings["per_usbdev_hdr"]     := "─── USB-Geräte ───"
    Strings["per_input_hdr"]      := "─── Eingabegeräte ───"
    Strings["per_input_name"]     := "Name"
    Strings["per_input_desc"]     := "Beschreibung"
    Strings["per_input_devid"]    := "Geräte-ID"
    Strings["per_input_status"]   := "Status"
    Strings["per_cam_hdr"]        := "─── Kameras && Bildgebung ───"
    Strings["per_cam_name"]       := "Name"
    Strings["per_cam_mfg"]        := "Hersteller"
    Strings["per_cam_status"]     := "Status"
    Strings["per_bt_hdr"]         := "─── Bluetooth ───"
    Strings["per_bt_name"]        := "Name"
    Strings["per_bt_mfg"]         := "Hersteller"
    Strings["per_bt_status"]      := "Status"
    Strings["per_none"]           := "Keine Peripheriegeräte gefunden"
}

; Shorthand translation lookup
T(key) {
    global Strings
    return Strings.Has(key) ? Strings[key] : key
}

; Simple placeholder replacement: {1}, {2}, {3}
TF(key, params*) {
    result := T(key)
    for idx, val in params
        result := StrReplace(result, "{" . idx . "}", val)
    return result
}

; ═══════════════════════════════════════════════════════════════
;  ASYNC LOADING
; ═══════════════════════════════════════════════════════════════

ScheduleDataLoad() {
    SetTimer(DoDataLoad, -50)
}

DoDataLoad() {
    global AllData, GuiCtx
    ctx := GuiCtx

    ctx.sb.SetText(T("sb_collecting"))

    ctx.btnExport.Opt("+Disabled")
    ctx.btnClipboard.Opt("+Disabled")
    ctx.btnRefresh.Opt("+Disabled")

    for key in ctx.tabKeys {
        if (ctx.listViews.Has(key)) {
            lv := ctx.listViews[key]
            lv.Delete()
            lv.Add("", T("loading"), T("loading_detail"))
        }
    }

    CollectAllDataProgressive()

    totalItems := 0
    for key, arr in AllData
        totalItems += arr.Length
    adminHint := IsRunAsAdmin() ? T("admin_yes") : T("admin_tip")
    ctx.sb.SetText(TF("sb_done", totalItems, AllData.Count, adminHint))

    ctx.btnExport.Opt("-Disabled")
    ctx.btnClipboard.Opt("-Disabled")
    ctx.btnRefresh.Opt("-Disabled")
}

; Populate a single tab's ListView immediately after its data is ready
PopulateSingleTab(key) {
    global AllData, GuiCtx
    if (!GuiCtx.listViews.Has(key) || !AllData.Has(key))
        return
    lv := GuiCtx.listViews[key]
    lv.Delete()
    for entry in AllData[key] {
        label := entry[1]
        val   := entry[2]
        if (SubStr(label, 1, 3) = "───")
            lv.Add("", label, val)
        else
            lv.Add("", "  " . label, val)
    }
}

PopulateAllTabs(tabKeys, listViews) {
    global AllData
    for key in tabKeys {
        if (listViews.Has(key)) {
            lv := listViews[key]
            lv.Delete()
            if (AllData.Has(key)) {
                for entry in AllData[key] {
                    label := entry[1]
                    val   := entry[2]
                    if (SubStr(label, 1, 3) = "───")
                        lv.Add("", label, val)
                    else
                        lv.Add("", "  " . label, val)
                }
            }
        }
    }
}

; ═══════════════════════════════════════════════════════════════
;  DATA COLLECTION — optimized with cached WMI and shared queries
; ═══════════════════════════════════════════════════════════════

; Cache WMI service connections to avoid repeated COM setup overhead.
; A single ComObjGet("winmgmts:") takes ~50-100ms; with 23 queries
; that alone adds 1-2 seconds. Caching cuts it to one per namespace.

GetWmiCimv2() {
    global WmiCimv2
    if (!IsObject(WmiCimv2))
        WmiCimv2 := ComObjGet("winmgmts:")
    return WmiCimv2
}

GetWmiRootWmi() {
    global WmiRootWmi
    if (!IsObject(WmiRootWmi))
        WmiRootWmi := ComObjGet("winmgmts:\\.\root\wmi")
    return WmiRootWmi
}

ResetWmiCache() {
    global WmiCimv2, WmiRootWmi, SharedOSData
    WmiCimv2    := ""
    WmiRootWmi  := ""
    SharedOSData := ""
}

; Query Win32_OperatingSystem once, cache the result object
GetSharedOSData() {
    global SharedOSData
    if (!IsObject(SharedOSData)) {
        try {
            for obj in GetWmiCimv2().ExecQuery("SELECT * FROM Win32_OperatingSystem")
                SharedOSData := obj
        }
    }
    return SharedOSData
}

; Progressive collection: fetch each category and immediately
; populate its tab so the user sees results streaming in.
CollectAllDataProgressive() {
    global AllData

    ResetWmiCache()

    ; Pre-fetch the shared OS data (used by OS + Memory tabs)
    GetSharedOSData()

    ; Collect and display each tab progressively
    categories := [
        ["OS",          GetOSInfo.Bind()],
        ["CPU",         GetCPUInfo.Bind()],
        ["Memory",      GetMemoryInfo.Bind()],
        ["GPU",         GetGPUInfo.Bind()],
        ["Disks",       GetDiskInfo.Bind()],
        ["Network",     GetNetworkInfo.Bind()],
        ["Mainboard",   GetMainboardInfo.Bind()],
        ["Audio",       GetAudioInfo.Bind()],
        ["Printers",    GetPrinterInfo.Bind()],
        ["Peripherals", GetPeripheralInfo.Bind()]
    ]

    for cat in categories {
        key      := cat[1]
        collector := cat[2]
        AllData[key] := collector.Call()
        PopulateSingleTab(key)
    }

    ResetWmiCache()
}

; ─── OS & System ────────────────────────────────────────────────
GetOSInfo() {
    info := []
    try {
        obj := GetSharedOSData()
        if (IsObject(obj)) {
            ; Snapshot all values from the COM object first
            d := Map()
            d["Caption"] := obj.Caption, d["Version"] := obj.Version
            d["BuildNumber"] := obj.BuildNumber, d["OSArchitecture"] := obj.OSArchitecture
            d["InstallDate"] := obj.InstallDate, d["LastBootUpTime"] := obj.LastBootUpTime
            d["SystemDirectory"] := obj.SystemDirectory, d["WindowsDirectory"] := obj.WindowsDirectory
            d["RegisteredUser"] := obj.RegisteredUser, d["SerialNumber"] := obj.SerialNumber

            info.Push([T("os_name"), d["Caption"]])
            info.Push([T("os_version"), d["Version"]])
            info.Push([T("os_build"), d["BuildNumber"]])
            info.Push([T("os_arch"), d["OSArchitecture"]])
            info.Push([T("os_install"), FormatWmiDate(d["InstallDate"])])
            info.Push([T("os_boot"), FormatWmiDate(d["LastBootUpTime"])])
            info.Push([T("os_sysdir"), d["SystemDirectory"]])
            info.Push([T("os_windir"), d["WindowsDirectory"]])
            info.Push([T("os_user_reg"), d["RegisteredUser"]])
            info.Push([T("os_serial"), d["SerialNumber"]])
            try {
                bootRaw := d["LastBootUpTime"]
                if (bootRaw != "") {
                    bootTS := DateDiff(A_Now, SubStr(bootRaw,1,4) . SubStr(bootRaw,5,2) . SubStr(bootRaw,7,2) . SubStr(bootRaw,9,2) . SubStr(bootRaw,11,2) . SubStr(bootRaw,13,2), "Seconds")
                    info.Push([T("os_uptime"), (bootTS // 86400) . "d " . (Mod(bootTS, 86400) // 3600) . "h " . (Mod(bootTS, 3600) // 60) . "m"])
                }
            }
        }
    }
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_ComputerSystem", ["Name","Domain","Manufacturer","Model","SystemType","TotalPhysicalMemory"])
        for d in rows {
            info.Push([T("os_hostname"), d["Name"]])
            info.Push([T("os_domain"), d["Domain"]])
            info.Push([T("os_manufacturer"), d["Manufacturer"]])
            info.Push([T("os_model"), d["Model"]])
            info.Push([T("os_systype"), d["SystemType"]])
            info.Push([T("os_totalram"), Round(d["TotalPhysicalMemory"] / (1024**3), 1) . " GB"])
        }
    }
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_TimeZone", ["Caption"])
        for d in rows
            info.Push([T("os_timezone"), d["Caption"]])
    }
    info.Push([T("os_curuser"), A_UserName])
    info.Push([T("os_locale"), Format("0x{:04X}", DllCall("GetUserDefaultUILanguage", "UShort"))])
    return info
}

; ─── CPU ────────────────────────────────────────────────────────
GetCPUInfo() {
    info := []
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_Processor", ["Name","Manufacturer","Description","NumberOfCores","NumberOfLogicalProcessors","MaxClockSpeed","CurrentClockSpeed","L2CacheSize","L3CacheSize","SocketDesignation","CurrentVoltage","Status"])
        for d in rows {
            info.Push([T("cpu_name"), Trim(d["Name"])])
            info.Push([T("cpu_mfg"), d["Manufacturer"]])
            info.Push([T("cpu_desc"), d["Description"]])
            info.Push([T("cpu_cores"), String(d["NumberOfCores"])])
            info.Push([T("cpu_threads"), String(d["NumberOfLogicalProcessors"])])
            info.Push([T("cpu_baseclock"), d["MaxClockSpeed"] . " MHz"])
            info.Push([T("cpu_curclock"), d["CurrentClockSpeed"] . " MHz"])
            info.Push([T("cpu_l2"), FormatBytes(d["L2CacheSize"] * 1024)])
            info.Push([T("cpu_l3"), FormatBytes(d["L3CacheSize"] * 1024)])
            info.Push([T("cpu_socket"), d["SocketDesignation"]])
            info.Push([T("cpu_voltage"), Round(d["CurrentVoltage"] / 10, 2) . " V"])
            info.Push([T("cpu_status"), d["Status"]])
        }
    }
    return info
}

; ─── Memory ─────────────────────────────────────────────────────
GetMemoryInfo() {
    info := []
    try {
        obj := GetSharedOSData()
        if (IsObject(obj)) {
            tv := obj.TotalVisibleMemorySize, fv := obj.FreePhysicalMemory
            tvs := obj.TotalVirtualMemorySize, fvs := obj.FreeVirtualMemory
            totalVis := Round(tv / (1024**2), 2)
            freeVis  := Round(fv / (1024**2), 2)
            usedVis  := Round(totalVis - freeVis, 2)
            pctUsed  := Round((usedVis / totalVis) * 100, 1)
            info.Push([T("mem_total"), totalVis . " GB"])
            info.Push([T("mem_used"), usedVis . " GB (" . pctUsed . "%)"])
            info.Push([T("mem_avail"), freeVis . " GB"])
            info.Push([T("mem_vtotal"), Round(tvs / (1024**2), 2) . " GB"])
            info.Push([T("mem_vfree"), Round(fvs / (1024**2), 2) . " GB"])
			info.Push(["", ""])
            info.Push([T("mem_dimm_hdr"), ""])
        }
    }
    slotNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_PhysicalMemory", ["Capacity","ConfiguredClockSpeed","Manufacturer","PartNumber","FormFactor","SMBIOSMemoryType","BankLabel","DeviceLocator"])
        for d in rows {
            slotNum++
            slotPfx := "Slot " . slotNum . " — "
            info.Push([slotPfx . T("mem_capacity"), Round(d["Capacity"] / (1024**3), 1) . " GB"])
            info.Push([slotPfx . T("mem_speed"), String(d["ConfiguredClockSpeed"]) . " MHz"])
            info.Push([slotPfx . T("mem_mfg"), d["Manufacturer"]])
            info.Push([slotPfx . T("mem_part"), Trim(d["PartNumber"])])
            info.Push([slotPfx . T("mem_form"), GetMemFormFactor(d["FormFactor"])])
            info.Push([slotPfx . T("mem_type"), GetMemType(d["SMBIOSMemoryType"])])
            info.Push([slotPfx . T("mem_bank"), d["BankLabel"] . " / " . d["DeviceLocator"]])
            if (slotNum >= 1)
                info.Push(["", ""])
        }
    }
    if (slotNum = 0)
        info.Push(["DIMM Info", T("mem_admin")])
    return info
}

GetMemFormFactor(code) {
    static forms := Map(
        0, "Unknown", 1, "Other", 2, "SIP", 3, "DIP", 4, "ZIP",
        5, "SOJ", 6, "Proprietary", 7, "SIMM", 8, "DIMM", 9, "TSOP",
        10, "PGA", 11, "RIMM", 12, "SODIMM", 13, "SRIMM", 14, "SMD",
        15, "SSMP", 16, "QFP", 17, "TQFP", 18, "SOIC", 19, "LCC",
        20, "PLCC", 21, "BGA", 22, "FPBGA", 23, "LGA"
    )
    return forms.Has(code) ? forms[code] : "Unknown (" . code . ")"
}

GetMemType(code) {
    static types := Map(
        0, "Unknown", 20, "DDR", 21, "DDR2", 22, "DDR2 FB-DIMM",
        24, "DDR3", 26, "DDR4", 30, "LPDDR4", 34, "DDR5", 35, "LPDDR5"
    )
    return types.Has(code) ? types[code] : "Type " . code
}

; ─── GPU ────────────────────────────────────────────────────────
GetGPUInfo() {
    info := []
    gpuNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_VideoController", ["Name","AdapterCompatibility","DriverVersion","DriverDate","AdapterRAM","VideoModeDescription","CurrentHorizontalResolution","CurrentVerticalResolution","CurrentRefreshRate","CurrentBitsPerPixel","Status","PNPDeviceID"])
        for d in rows {
            gpuNum++
            if (gpuNum > 1)
                info.Push(["─── GPU " . gpuNum . " ───", ""])
            info.Push([T("gpu_name"), d["Name"]])
            info.Push([T("gpu_compat"), d["AdapterCompatibility"]])
            info.Push([T("gpu_driver"), d["DriverVersion"]])
            info.Push([T("gpu_driverdate"), FormatWmiDate(d["DriverDate"])])
            vram := Round(d["AdapterRAM"] / (1024**3), 1)
            if (vram <= 0)
                vram := ">4 (WMI limit)"
            info.Push([T("gpu_vram"), vram . (IsNumber(vram) ? " GB" : "")])
            info.Push([T("gpu_vidmode"), d["VideoModeDescription"]])
            info.Push([T("gpu_res"), d["CurrentHorizontalResolution"] . " × " . d["CurrentVerticalResolution"]])
            info.Push([T("gpu_refresh"), d["CurrentRefreshRate"] . " Hz"])
            info.Push([T("gpu_bpp"), String(d["CurrentBitsPerPixel"])])
            info.Push([T("gpu_status"), d["Status"]])
            info.Push([T("gpu_pnp"), d["PNPDeviceID"]])
        }
    }

    ; ─── Monitor info — ordered by display index, primary first ──
    monitors := []
    adapterIdx := 0
    loop {
        devAdapter := Buffer(840, 0)
        NumPut("UInt", 840, devAdapter, 0)
        if (!DllCall("EnumDisplayDevicesW", "Ptr", 0, "UInt", adapterIdx, "Ptr", devAdapter, "UInt", 0))
            break
        adapterIdx++
        adapterName  := StrGet(devAdapter.Ptr + 4, 32, "UTF-16")
        adapterFlags := NumGet(devAdapter, 324, "UInt")

        if (!(adapterFlags & 0x1))
            continue

        adResW := 0, adResH := 0, adRefresh := 0
        devMode := Buffer(788, 0)
        NumPut("UShort", 788, devMode, 68)
        if (DllCall("EnumDisplaySettingsW", "Ptr", StrPtr(adapterName), "Int", -1, "Ptr", devMode)) {
            adResW    := NumGet(devMode, 172, "UInt")
            adResH    := NumGet(devMode, 176, "UInt")
            adRefresh := NumGet(devMode, 184, "UInt")
        }

        monIdx := 0
        loop {
            devMon := Buffer(840, 0)
            NumPut("UInt", 840, devMon, 0)
            if (!DllCall("EnumDisplayDevicesW", "Ptr", StrPtr(adapterName), "UInt", monIdx, "Ptr", devMon, "UInt", 0x1))
                break
            monIdx++
            monDeviceString := StrGet(devMon.Ptr + 68, 128, "UTF-16")
            monDeviceId     := StrGet(devMon.Ptr + 328, 128, "UTF-16")
            isPrimary       := (adapterFlags & 0x4) ? true : false

            monitors.Push({
                adapterName:  adapterName,
                deviceString: monDeviceString,
                deviceId:     monDeviceId,
                isPrimary:    isPrimary,
                resW:         adResW,
                resH:         adResH,
                refreshHz:    adRefresh
            })
        }
    }

    sortedMons := []
    for m in monitors {
        if (m.isPrimary)
            sortedMons.InsertAt(1, m)
        else
            sortedMons.Push(m)
    }

    ; Snapshot WmiMonitorID and WmiMonitorConnectionParams into maps
    edidNames := Map()
    connTypes := Map()
    try {
        for obj in GetWmiRootWmi().ExecQuery("SELECT * FROM WmiMonitorID") {
            pathKey := NormalizeInstancePath(obj.InstanceName)
            edidNames[pathKey] := {
                name:     DecodeWmiUint16Array(obj.UserFriendlyName),
                mfg:      DecodeWmiUint16Array(obj.ManufacturerName),
                serial:   DecodeWmiUint16Array(obj.SerialNumberID),
                prodCode: DecodeWmiUint16Array(obj.ProductCodeID)
            }
        }
    }
    try {
        for obj in GetWmiRootWmi().ExecQuery("SELECT * FROM WmiMonitorConnectionParams") {
            pathKey := NormalizeInstancePath(obj.InstanceName)
            connTypes[pathKey] := GetVideoOutputType(obj.VideoOutputTechnology)
        }
    }

    monNum := 0
    for m in sortedMons {
        monNum++
        primaryTag := m.isPrimary ? ("  ★ " . T("mon_primary")) : ""
		info.Push(["", ""])
        info.Push(["─── Monitor " . monNum . primaryTag . " ───", ""])

        monPathKey := NormalizeDeviceId(m.deviceId)
        matched := false
        if (monPathKey != "") {
            for edidKey, edid in edidNames {
                if (edidKey != "" && edidKey = monPathKey) {
                    dispName := (edid.name != "") ? edid.name : m.deviceString
                    info.Push([T("mon_name"), dispName])
                    if (edid.mfg != "")
                        info.Push([T("mon_mfg"), edid.mfg])
                    if (edid.serial != "")
                        info.Push([T("mon_serial"), edid.serial])
                    if (edid.prodCode != "")
                        info.Push([T("mon_prodcode"), edid.prodCode])
                    matched := true
                    break
                }
            }
        }
        if (!matched)
            info.Push([T("mon_name"), m.deviceString])

        if (m.resW > 0)
            info.Push([T("mon_res"), m.resW . " × " . m.resH])
        if (m.refreshHz > 0)
            info.Push([T("mon_refresh"), m.refreshHz . " Hz"])

        if (monPathKey != "") {
            for connKey, connStr in connTypes {
                if (connKey != "" && connKey = monPathKey) {
                    info.Push([T("mon_conn"), connStr])
                    break
                }
            }
        }

        info.Push([T("mon_adapter"), m.adapterName])
        info.Push([T("mon_devid"), m.deviceId])
    }

    if (monNum = 0)
        info.Push([T("mon_name"), T("mon_none")])
    return info
}

NormalizeInstancePath(instName) {
    parts := StrSplit(instName, "\")
    return (parts.Length >= 2) ? parts[2] : instName
}

NormalizeDeviceId(devId) {
    parts := StrSplit(devId, "\")
    return (parts.Length >= 2) ? parts[2] : devId
}

DecodeWmiUint16Array(arr) {
    if (!IsObject(arr))
        return ""
    result := ""
    for idx, charCode in arr {
        if (charCode = 0)
            break
        result .= Chr(charCode)
    }
    return Trim(result)
}

GetVideoOutputType(code) {
    static types := Map(
        -1, "Other",  0, "VGA (HD15)",  1, "S-Video",  2, "Composite",
         3, "Component",  4, "DVI",  5, "HDMI",  6, "LVDS",
         8, "D-Jpn",  9, "SDI", 10, "DisplayPort (ext)",
        11, "DisplayPort (emb)", 12, "UDI (ext)", 13, "UDI (emb)",
        14, "SDTV Dongle", 15, "Miracast", 16, "Internal"
    )
    return types.Has(code) ? types[code] : "Unknown (" . code . ")"
}

; ─── Disks ──────────────────────────────────────────────────────
GetDiskInfo() {
    info := []
    diskNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_DiskDrive", ["Model","InterfaceType","SerialNumber","FirmwareRevision","Size","MediaType","Partitions","Status"])
        for d in rows {
            diskNum++
            if (diskNum > 1)
                info.Push(["", ""])
            info.Push(["─── Physical Disk " . diskNum . " ───", ""])
            info.Push([T("disk_model"), d["Model"]])
            info.Push([T("disk_iface"), d["InterfaceType"]])
            info.Push([T("disk_serial"), Trim(d["SerialNumber"])])
            info.Push([T("disk_fw"), d["FirmwareRevision"]])
            info.Push([T("disk_size"), FormatBytes(d["Size"])])
            info.Push([T("disk_media"), d["MediaType"]])
            info.Push([T("disk_parts"), String(d["Partitions"])])
            info.Push([T("disk_status"), d["Status"]])
        }
    }
    info.Push(["", ""])
    info.Push([T("disk_vol_hdr"), ""])
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_LogicalDisk WHERE DriveType=3", ["DeviceID","FileSystem","VolumeName","Size","FreeSpace"])
        for d in rows {
            letter := d["DeviceID"]
            total  := d["Size"]
            free   := d["FreeSpace"]
            used   := total - free
            pct    := (total > 0) ? Round((used / total) * 100, 1) : 0
            info.Push([letter . " — " . T("disk_fs"), d["FileSystem"]])
            info.Push([letter . " — " . T("disk_label"), (d["VolumeName"] != "") ? d["VolumeName"] : T("disk_nolabel")])
            info.Push([letter . " — " . T("disk_total"), FormatBytes(total)])
            info.Push([letter . " — " . T("disk_used"), FormatBytes(used) . "  (" . pct . "%)"])
            info.Push([letter . " — " . T("disk_free"), FormatBytes(free)])
            barFull := 30
            barUsed := Round(pct / 100 * barFull)
            bar := ""
            loop barUsed
                bar .= "█"
            loop (barFull - barUsed)
                bar .= "░"
            info.Push([letter . " — " . T("disk_usage"), "[" . bar . "] " . pct . "%"])
            info.Push(["", ""])
        }
    }
    return info
}

; ─── Network ────────────────────────────────────────────────────
GetNetworkInfo() {
    info := []
    adapterNum := 0
    snapshots := []
    try {
        ; Network adapters have array properties (IPAddress, IPSubnet, etc.)
        ; that WmiCollect can't handle generically, so snapshot manually
        resultSet := GetWmiCimv2().ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=TRUE")
        for obj in resultSet {
            try {
                d := Map()
                d["Description"] := obj.Description
                d["MACAddress"] := obj.MACAddress
                d["DHCPEnabled"] := obj.DHCPEnabled
                d["DHCPServer"] := ""
                try d["DHCPServer"] := obj.DHCPServer
                d["IPAddress"] := "", d["IPSubnet"] := "", d["Gateway"] := "", d["DNS"] := ""
                try {
                    a := obj.IPAddress
                    if (IsObject(a)) {
                        for idx, v in a
                            d["IPAddress"] .= (d["IPAddress"] != "" ? ", " : "") . v
                    }
                }
                try {
                    a := obj.IPSubnet
                    if (IsObject(a)) {
                        for idx, v in a
                            d["IPSubnet"] .= (d["IPSubnet"] != "" ? ", " : "") . v
                    }
                }
                try {
                    a := obj.DefaultIPGateway
                    if (IsObject(a)) {
                        for idx, v in a
                            d["Gateway"] .= (d["Gateway"] != "" ? ", " : "") . v
                    }
                }
                try {
                    a := obj.DNSServerSearchOrder
                    if (IsObject(a)) {
                        for idx, v in a
                            d["DNS"] .= (d["DNS"] != "" ? ", " : "") . v
                    }
                }
                snapshots.Push(d)
            }
        }
    }
    ; Format from snapshots (outside try)
    for d in snapshots {
        adapterNum++
        if (adapterNum > 1)
            info.Push(["", ""])
        info.Push(["─── Adapter " . adapterNum . " ───", ""])
        info.Push([T("net_desc"), d["Description"]])
        info.Push([T("net_mac"), d["MACAddress"]])
        if (d["IPAddress"] != "")
            info.Push([T("net_ip"), d["IPAddress"]])
        if (d["IPSubnet"] != "")
            info.Push([T("net_subnet"), d["IPSubnet"]])
        if (d["Gateway"] != "")
            info.Push([T("net_gw"), d["Gateway"]])
        if (d["DNS"] != "")
            info.Push([T("net_dns"), d["DNS"]])
        info.Push([T("net_dhcp"), d["DHCPEnabled"] ? T("yes") : T("no")])
        if (d["DHCPEnabled"] && d["DHCPServer"] != "")
            info.Push([T("net_dhcpsrv"), d["DHCPServer"]])
    }
    return info
}

; ─── Mainboard / BIOS ──────────────────────────────────────────
GetMainboardInfo() {
    info := []
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_BaseBoard", ["Manufacturer","Product","Version","SerialNumber"])
        for d in rows {
            info.Push([T("mb_mfg"), d["Manufacturer"]])
            info.Push([T("mb_product"), d["Product"]])
            info.Push([T("mb_version"), d["Version"]])
            info.Push([T("mb_serial"), d["SerialNumber"]])
        }
    }
    info.Push(["", ""])
    info.Push([T("bios_hdr"), ""])
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_BIOS", ["Manufacturer","SMBIOSBIOSVersion","ReleaseDate","SMBIOSMajorVersion","SMBIOSMinorVersion","SerialNumber"])
        for d in rows {
            info.Push([T("bios_mfg"), d["Manufacturer"]])
            info.Push([T("bios_ver"), d["SMBIOSBIOSVersion"]])
            info.Push([T("bios_date"), FormatWmiDate(d["ReleaseDate"])])
            info.Push([T("bios_smbios"), d["SMBIOSMajorVersion"] . "." . d["SMBIOSMinorVersion"]])
            info.Push([T("bios_serial"), d["SerialNumber"]])
        }
    }
    info.Push(["", ""])
    info.Push([T("tpm_hdr"), ""])
    try {
        tpmFound := false
        for obj in ComObjGet("winmgmts:\\.\root\cimv2\Security\MicrosoftTpm").ExecQuery("SELECT * FROM Win32_Tpm") {
            tpmFound := true
            mfg := obj.ManufacturerIdTxt, ver := obj.SpecVersion
            info.Push([T("tpm_present"), T("yes")])
            info.Push([T("tpm_mfg"), mfg])
            info.Push([T("tpm_ver"), ver])
        }
        if (!tpmFound)
            info.Push(["TPM", T("tpm_no")])
    } catch {
        info.Push(["TPM", T("tpm_admin")])
    }
    return info
}

; ─── Audio ──────────────────────────────────────────────────────
GetAudioInfo() {
    info := []
    devNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_SoundDevice", ["Name","Manufacturer","Status","PNPDeviceID"])
        for d in rows {
            devNum++
            if (devNum > 1)
                info.Push(["", ""])
            info.Push(["─── Audio " . devNum . " ───", ""])
            info.Push([T("audio_name"), d["Name"]])
            info.Push([T("audio_mfg"), d["Manufacturer"]])
            info.Push([T("audio_status"), d["Status"]])
            info.Push([T("audio_pnp"), d["PNPDeviceID"]])
        }
    }
    if (devNum = 0)
        info.Push(["Audio", T("audio_none")])
    return info
}

; ─── Printers ───────────────────────────────────────────────────
GetPrinterInfo() {
    info := []
    prnNum := 0
    snapshots := []
    try {
        ; Printers have CapabilityDescriptions (array), snapshot manually
        resultSet := GetWmiCimv2().ExecQuery("SELECT * FROM Win32_Printer")
        for obj in resultSet {
            try {
                d := Map()
                d["Name"] := obj.Name, d["DriverName"] := obj.DriverName
                d["PortName"] := obj.PortName, d["Default"] := obj.Default
                d["Shared"] := obj.Shared, d["Network"] := obj.Network
                d["PrinterStatus"] := obj.PrinterStatus
                d["ShareName"] := "", d["Location"] := ""
                d["HorizontalResolution"] := 0, d["VerticalResolution"] := 0
                d["HasDuplex"] := false, d["HasColor"] := false
                try d["ShareName"] := obj.ShareName
                try d["Location"] := obj.Location
                try d["HorizontalResolution"] := obj.HorizontalResolution
                try d["VerticalResolution"] := obj.VerticalResolution
                try {
                    capArr := obj.CapabilityDescriptions
                    if (IsObject(capArr)) {
                        for idx, cap in capArr {
                            if (InStr(cap, "Duplex"))
                                d["HasDuplex"] := true
                            if (InStr(cap, "Color"))
                                d["HasColor"] := true
                        }
                    }
                }
                snapshots.Push(d)
            }
        }
    }
    ; Format from snapshots (outside try so a single failure doesn't kill all)
    for d in snapshots {
        prnNum++
        if (prnNum > 1)
            info.Push(["", ""])
        defTag := d["Default"] ? ("  ★ " . T("prn_default")) : ""
        info.Push(["─── " . d["Name"] . defTag . " ───", ""])
        info.Push([T("prn_name"), d["Name"]])
        info.Push([T("prn_driver"), d["DriverName"]])
        info.Push([T("prn_port"), d["PortName"]])
        info.Push([T("prn_default"), d["Default"] ? T("yes") : T("no")])
        info.Push([T("prn_shared"), d["Shared"] ? T("yes") : T("no")])
        if (d["Shared"] && d["ShareName"] != "")
            info.Push([T("prn_sharename"), d["ShareName"]])
        info.Push([T("prn_network"), d["Network"] ? T("yes") : T("no")])
        if (d["Location"] != "")
            info.Push([T("prn_location"), d["Location"]])
        if (IsNumber(d["HorizontalResolution"]) && d["HorizontalResolution"] > 0)
            info.Push([T("prn_horizontal"), d["HorizontalResolution"] . " dpi"])
        if (IsNumber(d["VerticalResolution"]) && d["VerticalResolution"] > 0)
            info.Push([T("prn_vertical"), d["VerticalResolution"] . " dpi"])
        info.Push([T("prn_duplex"), d["HasDuplex"] ? T("yes") : T("no")])
        info.Push([T("prn_color"), d["HasColor"] ? T("yes") : T("no")])
        info.Push([T("prn_status"), GetPrinterStatus(d["PrinterStatus"])])
    }
    if (prnNum = 0)
        info.Push(["Printers", T("prn_none")])
    return info
}

GetPrinterStatus(code) {
    static statuses := Map(
        1, "Other", 2, "Unknown", 3, "Idle", 4, "Printing",
        5, "Warmup", 6, "Stopped Printing", 7, "Offline"
    )
    return statuses.Has(code) ? statuses[code] : "Status " . code
}

; ─── Peripherals ────────────────────────────────────────────────
GetPeripheralInfo() {
    info := []
    totalDevs := 0

    ; ── USB Controllers ─────────────────────────────────────────
    info.Push([T("per_usb_hdr"), ""])
    ctrlNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_USBController", ["Name","Manufacturer","Status"])
        for d in rows {
            ctrlNum++
            totalDevs++
            if (ctrlNum > 1)
                info.Push(["", ""])
            info.Push([T("per_usb_name"), d["Name"]])
            info.Push([T("per_usb_mfg"), d["Manufacturer"]])
            info.Push([T("per_usb_status"), d["Status"]])
        }
    }

    ; ── USB Connected Devices ───────────────────────────────────
    info.Push(["", ""])
    info.Push([T("per_usbdev_hdr"), ""])
    usbNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_PnPEntity WHERE DeviceID LIKE 'USB\\%' AND NOT Name LIKE '%Hub%' AND NOT Name LIKE '%Controller%' AND NOT Name LIKE '%Composite%'", ["Name","Manufacturer","DeviceID","Status"])
        for d in rows {
            usbNum++
            totalDevs++
            if (usbNum > 1)
                info.Push(["", ""])
            info.Push([T("per_usb_name"), d["Name"]])
            if (d["Manufacturer"] != "" && d["Manufacturer"] != "(Standard USB Host Controller)")
                info.Push([T("per_usb_mfg"), d["Manufacturer"]])
            info.Push([T("per_usb_devid"), d["DeviceID"]])
            info.Push([T("per_usb_status"), d["Status"]])
        }
    }

    ; ── Input Devices ───────────────────────────────────────────
    info.Push(["", ""])
    info.Push([T("per_input_hdr"), ""])
    inputNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_Keyboard", ["Name","Description","Status"])
        for d in rows {
            inputNum++
            totalDevs++
            if (inputNum > 1)
                info.Push(["", ""])
            info.Push([T("per_input_name"), d["Name"]])
            info.Push([T("per_input_desc"), d["Description"]])
            info.Push([T("per_input_status"), d["Status"]])
        }
    }
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_PointingDevice", ["Name","Description","DeviceID","Status"])
        for d in rows {
            inputNum++
            totalDevs++
            if (inputNum > 1)
                info.Push(["", ""])
            info.Push([T("per_input_name"), d["Name"]])
            info.Push([T("per_input_desc"), d["Description"]])
            if (d["DeviceID"] != "")
                info.Push([T("per_input_devid"), d["DeviceID"]])
            info.Push([T("per_input_status"), d["Status"]])
        }
    }

    ; ── Cameras / Imaging Devices ───────────────────────────────
    info.Push(["", ""])
    info.Push([T("per_cam_hdr"), ""])
    camNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_PnPEntity WHERE PNPClass='Camera' OR PNPClass='Image'", ["Name","Manufacturer","Status"])
        for d in rows {
            camNum++
            totalDevs++
            if (camNum > 1)
                info.Push(["", ""])
            info.Push([T("per_cam_name"), d["Name"]])
            if (d["Manufacturer"] != "")
                info.Push([T("per_cam_mfg"), d["Manufacturer"]])
            info.Push([T("per_cam_status"), d["Status"]])
        }
    }
    if (camNum = 0)
        info.Push([T("per_cam_name"), "—"])

    ; ── Bluetooth ───────────────────────────────────────────────
    info.Push(["", ""])
    info.Push([T("per_bt_hdr"), ""])
    btNum := 0
    try {
        rows := WmiCollect(GetWmiCimv2(), "SELECT * FROM Win32_PnPEntity WHERE PNPClass='Bluetooth'", ["Name","Manufacturer","Status"])
        for d in rows {
            btNum++
            totalDevs++
            if (btNum > 1)
                info.Push(["", ""])
            info.Push([T("per_bt_name"), d["Name"]])
            if (d["Manufacturer"] != "")
                info.Push([T("per_bt_mfg"), d["Manufacturer"]])
            info.Push([T("per_bt_status"), d["Status"]])
        }
    }
    if (btNum = 0)
        info.Push([T("per_bt_name"), "—"])

    if (totalDevs = 0)
        info := [["Peripherals", T("per_none")]]
    return info
}

; ═══════════════════════════════════════════════════════════════
;  HELPERS
; ═══════════════════════════════════════════════════════════════

; Execute a WMI query and immediately snapshot all requested properties
; into an array of Maps. This closes the WMI enumerator as fast as possible,
; freeing the WMI service for the next query. All formatting and processing
; happens afterwards on plain AHK data at native speed.
WmiCollect(wmiService, query, properties) {
    rows := []
    resultSet := wmiService.ExecQuery(query)
    for obj in resultSet {
        try {
            d := Map()
            for prop in properties {
                try
                    d[prop] := obj.%prop%
                catch
                    d[prop] := ""
            }
            rows.Push(d)
        }
    }
    return rows
}

IsRunAsAdmin() {
    return DllCall("shell32\IsUserAnAdmin")
}

FormatWmiDate(raw) {
    if (!raw || raw = "")
        return "N/A"
    return SubStr(raw, 1, 4) . "-" . SubStr(raw, 5, 2) . "-" . SubStr(raw, 7, 2) . "  " . SubStr(raw, 9, 2) . ":" . SubStr(raw, 11, 2) . ":" . SubStr(raw, 13, 2)
}

FormatBytes(bytes) {
    if (!IsNumber(bytes) || bytes = 0)
        return "N/A"
    bytes := Number(bytes)
    units := ["B", "KB", "MB", "GB", "TB", "PB"]
    i := 1
    while (bytes >= 1024 && i < units.Length) {
        bytes := bytes / 1024
        i++
    }
    return Round(bytes, 2) . " " . units[i]
}

IsNumber(val) {
    return (val is Number) || RegExMatch(String(val), "^\d+\.?\d*$")
}

; Get the actual height of the tab header strip (accounts for multi-row tabs)
; Uses TCM_ADJUSTRECT to ask the tab control where the display area starts
GetTabHeaderHeight(tabCtrl) {
    ; TCM_ADJUSTRECT = 0x1328
    ; Pass a RECT filled with the tab control's client area,
    ; wParam=FALSE asks "given this window rect, where is the display area?"
    ; The difference between the input top and output top = header height

    ; Get tab control client rect
    rc := Buffer(16, 0)
    DllCall("GetClientRect", "Ptr", tabCtrl.Hwnd, "Ptr", rc)
    ; rc now has {left=0, top=0, right=clientW, bottom=clientH}

    ; TCM_ADJUSTRECT with wParam=0: window rect → display rect
    DllCall("SendMessage", "Ptr", tabCtrl.Hwnd, "UInt", 0x1328, "Ptr", 0, "Ptr", rc)

    ; The top of the returned rect is where the content area starts
    displayTop := NumGet(rc, 4, "Int")

    ; Add a small padding buffer
    return (displayTop > 0) ? displayTop + 2 : 28
}

; ═══════════════════════════════════════════════════════════════
;  GUI
; ═══════════════════════════════════════════════════════════════

BuildMainWindow() {
    global GuiCtx

    WIN_W       := 820
    WIN_H       := 620
    MARGIN      := 10
    HEADER_H    := 50
    TAB_Y       := MARGIN + HEADER_H
    BTN_H       := 32
    BTN_W       := 130
    BTN_AREA    := BTN_H + 12
    SB_H        := 22
    LV_PAD_X    := 6
    LV_PAD_TOP  := 28
    LV_PAD_BOT  := 6

    TAB_W := WIN_W - (MARGIN * 2)
    TAB_H := WIN_H - TAB_Y - BTN_AREA - SB_H - MARGIN

    mainGui := Gui("+Resize +MinSize640x480", T("win_title"))
    mainGui.SetFont("s9", "Segoe UI")
    mainGui.BackColor := "FFFFFF"
    mainGui.MarginX := MARGIN
    mainGui.MarginY := MARGIN

    ; ─── Header ─────────────────────────────────────────────────
    mainGui.SetFont("s14 Bold c2B579A", "Segoe UI")
    mainGui.AddText("xm y8 w" . TAB_W, T("header"))
    mainGui.SetFont("s8 Norm c888888", "Segoe UI")
    mainGui.AddText("xm y33 w" . TAB_W, T("generated") . ": " . FormatTime(A_Now, "yyyy-MM-dd  HH:mm:ss") . "     •     " . A_ComputerName)
    mainGui.SetFont("s9 Norm c000000", "Segoe UI")

    ; ─── Tab Control ────────────────────────────────────────────
    tabNames := [T("tab_os"), T("tab_cpu"), T("tab_memory"), T("tab_gpu"), T("tab_disks"), T("tab_network"), T("tab_mainboard"), T("tab_audio"), T("tab_printers"), T("tab_peripherals")]
    tabKeys  := ["OS", "CPU", "Memory", "GPU", "Disks", "Network", "Mainboard", "Audio", "Printers", "Peripherals"]

    tabs := mainGui.AddTab3("xm y" . TAB_Y . " w" . TAB_W . " h" . TAB_H, tabNames)

    ; Dynamically measure tab header height (handles multi-row tab labels)
    LV_PAD_TOP := GetTabHeaderHeight(tabs)
    lvW := TAB_W - (LV_PAD_X * 2)
    lvH := TAB_H - LV_PAD_TOP - LV_PAD_BOT
    lvX := MARGIN + LV_PAD_X
    lvY := TAB_Y + LV_PAD_TOP

    listViews := Map()
    loop tabKeys.Length {
        tabs.UseTab(A_Index)
        key := tabKeys[A_Index]
        mainGui.SetFont("s9", "Segoe UI")
        lv := mainGui.AddListView(
            "x" . lvX . " y" . lvY . " w" . lvW . " h" . lvH
            . " +Report +NoSortHdr +Grid +LV0x4000",
            [T("col_property"), T("col_value")]
        )
        lv.ModifyCol(1, Round(lvW * 0.33))
        lv.ModifyCol(2, Round(lvW * 0.64))
        lv.Add("", T("loading"), T("loading_detail"))
        listViews[key] := lv
    }
    tabs.UseTab()

    ; ─── Bottom button bar ──────────────────────────────────────
    mainGui.SetFont("s9", "Segoe UI")
    btnY := TAB_Y + TAB_H + 6

    btnExport := mainGui.AddButton("xm y" . btnY . " w" . BTN_W . " h" . BTN_H . " +Disabled", T("btn_export"))
    btnExport.OnEvent("Click", (*) => ExportReport())

    btnClipboard := mainGui.AddButton("x+8 y" . btnY . " w" . BTN_W . " h" . BTN_H . " +Disabled", T("btn_clipboard"))
    btnClipboard.OnEvent("Click", (*) => CopyToClipboard())

    btnRefresh := mainGui.AddButton("x+8 y" . btnY . " w" . BTN_W . " h" . BTN_H . " +Disabled", T("btn_refresh"))
    btnRefresh.OnEvent("Click", (*) => DoRefresh())

    btnAbout := mainGui.AddButton("x+8 y" . btnY . " w" . BTN_W . " h" . BTN_H, T("btn_about"))
    btnAbout.OnEvent("Click", (*) => MsgBox(T("about_text"), T("about_title"), "64"))

    btnUpdate := mainGui.AddButton("x+8 y" . btnY . " w" . BTN_W . " h" . BTN_H, T("btn_update"))
    btnUpdate.OnEvent("Click", (*) => CheckForUpdate())

    ; ─── Status bar ─────────────────────────────────────────────
    sb := mainGui.AddStatusBar()
    sb.SetText(T("sb_starting"))

    ; ─── Store references globally for async access ─────────────
    GuiCtx.mainGui      := mainGui
    GuiCtx.tabs         := tabs
    GuiCtx.listViews    := listViews
    GuiCtx.tabKeys      := tabKeys
    GuiCtx.btnExport    := btnExport
    GuiCtx.btnClipboard := btnClipboard
    GuiCtx.btnRefresh   := btnRefresh
    GuiCtx.btnAbout     := btnAbout
    GuiCtx.btnUpdate    := btnUpdate
    GuiCtx.sb           := sb
    GuiCtx.MARGIN       := MARGIN
    GuiCtx.HEADER_H     := HEADER_H
    GuiCtx.BTN_H        := BTN_H
    GuiCtx.BTN_AREA     := BTN_AREA
    GuiCtx.SB_H         := SB_H
    GuiCtx.LV_PAD_X     := LV_PAD_X
    GuiCtx.LV_PAD_TOP   := LV_PAD_TOP
    GuiCtx.LV_PAD_BOT   := LV_PAD_BOT

    mainGui.OnEvent("Size", (thisGui, minMax, w, h) => OnResize(thisGui, GuiCtx, w, h, minMax))

    mainGui.OnEvent("Close", (*) => ExitApp())
    mainGui.Show("w" . WIN_W . " h" . WIN_H)
}

; ─── Resize handler ─────────────────────────────────────────────
OnResize(thisGui, ctx, w, h, minMax) {
    if (minMax = -1)
        return
    if (w < 400 || h < 300)
        return

    hwnd := thisGui.Hwnd
    DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x000B, "Ptr", 0, "Ptr", 0)

    try {
        M    := ctx.MARGIN
        tabY := M + ctx.HEADER_H
        tabW := w - (M * 2)
        tabH := h - tabY - ctx.BTN_AREA - ctx.SB_H - M
        if (tabH < 100)
            tabH := 100

        ctx.tabs.Move(, tabY, tabW, tabH)

        ; Recalculate tab header height (may have changed rows due to width)
        lvPadTop := GetTabHeaderHeight(ctx.tabs)
        lvW := tabW - (ctx.LV_PAD_X * 2)
        lvH := tabH - lvPadTop - ctx.LV_PAD_BOT
        lvX := M + ctx.LV_PAD_X
        lvY := tabY + lvPadTop
        if (lvH < 50)
            lvH := 50

        col1W := Round(lvW * 0.33)
        col2W := Round(lvW * 0.64)

        for key in ctx.tabKeys {
            if (ctx.listViews.Has(key)) {
                ctx.listViews[key].Move(lvX, lvY, lvW, lvH)
                ctx.listViews[key].ModifyCol(1, col1W)
                ctx.listViews[key].ModifyCol(2, col2W)
            }
        }

        btnY := tabY + tabH + 6
        ctx.btnExport.Move(, btnY)
        ctx.btnClipboard.Move(, btnY)
        ctx.btnRefresh.Move(, btnY)
        ctx.btnAbout.Move(, btnY)
        ctx.btnUpdate.Move(, btnY)
    }

    DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x000B, "Ptr", 1, "Ptr", 0)
    DllCall("RedrawWindow", "Ptr", hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0085)
}

; ═══════════════════════════════════════════════════════════════
;  REFRESH
; ═══════════════════════════════════════════════════════════════

DoRefresh() {
    global GuiCtx
    ctx := GuiCtx

    ctx.btnExport.Opt("+Disabled")
    ctx.btnClipboard.Opt("+Disabled")
    ctx.btnRefresh.Opt("+Disabled")
    ctx.sb.SetText(T("sb_refreshing"))

    for key in ctx.tabKeys {
        if (ctx.listViews.Has(key)) {
            lv := ctx.listViews[key]
            lv.Delete()
            lv.Add("", T("refreshing"), T("refreshing_detail"))
        }
    }

    SetTimer(DoRefreshWork, -50)
}

DoRefreshWork() {
    global AllData, GuiCtx
    ctx := GuiCtx

    CollectAllDataProgressive()

    totalItems := 0
    for key, arr in AllData
        totalItems += arr.Length
    adminHint := IsRunAsAdmin() ? T("admin_yes") : T("admin_tip")
    ctx.sb.SetText(TF("sb_refreshed", totalItems, FormatTime(A_Now, "HH:mm:ss"), adminHint))

    ctx.btnExport.Opt("-Disabled")
    ctx.btnClipboard.Opt("-Disabled")
    ctx.btnRefresh.Opt("-Disabled")
}

; ═══════════════════════════════════════════════════════════════
;  AUTO-UPDATE FROM GITHUB
; ═══════════════════════════════════════════════════════════════

CheckForUpdate() {
    global APP_VERSION, GITHUB_REPO, GuiCtx

    GuiCtx.btnUpdate.Opt("+Disabled")
    GuiCtx.sb.SetText("  ⬆  " . T("upd_checking"))

    try {
        ; Query GitHub API for latest release
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "https://api.github.com/repos/" . GITHUB_REPO . "/releases/latest", false)
        whr.SetRequestHeader("User-Agent", "SystemInfo-AHK/" . APP_VERSION)
        whr.SetRequestHeader("Accept", "application/vnd.github.v3+json")
        whr.Send()

        if (whr.Status != 200) {
            GuiCtx.btnUpdate.Opt("-Disabled")
            GuiCtx.sb.SetText("")
            MsgBox(T("upd_error") . "`nHTTP " . whr.Status, T("upd_error_title"), "16")
            return
        }

        responseText := whr.ResponseText

        ; Parse tag_name from JSON (lightweight — no JSON lib needed)
        remoteVersion := ""
        if (RegExMatch(responseText, '"tag_name"\s*:\s*"v?([^"]+)"', &m))
            remoteVersion := m[1]

        if (remoteVersion = "") {
            GuiCtx.btnUpdate.Opt("-Disabled")
            GuiCtx.sb.SetText("")
            MsgBox(T("upd_error") . "`nCould not parse version from response.", T("upd_error_title"), "16")
            return
        }

        ; Compare versions
        if (CompareVersions(remoteVersion, APP_VERSION) > 0) {
            ; Update available — ask user
            GuiCtx.sb.SetText("  ⬆  " . T("upd_available") . "  " . remoteVersion)
            choice := MsgBox(
                T("upd_available") . "`n`n"
                . T("upd_current") . ":  v" . APP_VERSION . "`n"
                . T("upd_latest") . ":  v" . remoteVersion . "`n`n"
                . T("upd_confirm"),
                T("upd_available"),
                "YesNo Icon!"
            )
            if (choice = "Yes") {
                DownloadAndInstallUpdate(responseText)
            } else {
                GuiCtx.btnUpdate.Opt("-Disabled")
                GuiCtx.sb.SetText("")
            }
        } else {
            ; Already up to date
            GuiCtx.btnUpdate.Opt("-Disabled")
            GuiCtx.sb.SetText("")
            MsgBox(TF("upd_noupdate", APP_VERSION), T("upd_noupdate_title"), "64")
        }
    } catch as e {
        GuiCtx.btnUpdate.Opt("-Disabled")
        GuiCtx.sb.SetText("")
        MsgBox(T("upd_error") . "`n" . e.Message, T("upd_error_title"), "16")
    }
}

DownloadAndInstallUpdate(responseText) {
    global GITHUB_REPO, GuiCtx

    GuiCtx.sb.SetText("  ⬇  " . T("upd_downloading"))

    try {
        ; ── Find the .zip asset URL from the release ────────────
        downloadUrl := ""
        pos := 1
        while (RegExMatch(responseText, '"browser_download_url"\s*:\s*"([^"]+)"', &m, pos)) {
            if (RegExMatch(m[1], "i)\.zip$")) {
                downloadUrl := m[1]
                break
            }
            pos := m.Pos + m.Len
        }

        if (downloadUrl = "") {
            GuiCtx.btnUpdate.Opt("-Disabled")
            GuiCtx.sb.SetText("")
            MsgBox(T("upd_dl_error") . "`nNo .zip asset found in the latest release.", T("upd_dl_error_title"), "16")
            return
        }

        ; ── Prepare paths ───────────────────────────────────────
        exePath    := A_ScriptFullPath                     ; the running .exe
        exeDir     := A_ScriptDir
        exeName    := ""
        SplitPath(exePath, &exeName)
        tempDir    := A_Temp . "\SystemInfo_Update_" . A_TickCount
        zipPath    := tempDir . "\update.zip"
        extractDir := tempDir . "\extracted"
        backupPath := exePath . ".bak"

        DirCreate(tempDir)
        DirCreate(extractDir)

        ; ── Download the .zip ───────────────────────────────────
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", downloadUrl, false)
        whr.SetRequestHeader("User-Agent", "SystemInfo-AHK-Updater")
        whr.Send()

        if (whr.Status != 200) {
            try DirDelete(tempDir, true)
            GuiCtx.btnUpdate.Opt("-Disabled")
            GuiCtx.sb.SetText("")
            MsgBox(T("upd_dl_error") . "`nHTTP " . whr.Status, T("upd_dl_error_title"), "16")
            return
        }

        ; Write zip to disk
        adoStream := ComObject("ADODB.Stream")
        adoStream.Type := 1  ; Binary
        adoStream.Open()
        adoStream.Write(whr.ResponseBody)
        adoStream.SaveToFile(zipPath, 2)  ; 2 = overwrite
        adoStream.Close()

        ; ── Extract the .zip using Shell32 ──────────────────────
        shell := ComObject("Shell.Application")
        zipFolder := shell.NameSpace(zipPath)
        destFolder := shell.NameSpace(extractDir)

        if (!zipFolder || !destFolder) {
            try DirDelete(tempDir, true)
            GuiCtx.btnUpdate.Opt("-Disabled")
            GuiCtx.sb.SetText("")
            MsgBox(T("upd_dl_error") . "`nFailed to open zip archive.", T("upd_dl_error_title"), "16")
            return
        }

        ; 0x14 = FOF_NOCONFIRMATION (0x10) | FOF_SILENT (0x04)
        destFolder.CopyHere(zipFolder.Items(), 0x14)

        ; ── Find the .exe in extracted files (recursive) ────────
        newExePath := FindExeInDir(extractDir)

        if (newExePath = "") {
            try DirDelete(tempDir, true)
            GuiCtx.btnUpdate.Opt("-Disabled")
            GuiCtx.sb.SetText("")
            MsgBox(T("upd_dl_error") . "`nNo .exe file found in the downloaded archive.", T("upd_dl_error_title"), "16")
            return
        }

        ; ── Replace the running .exe via batch trampoline ───────
        ; A running .exe cannot overwrite itself, so we write a
        ; small batch script that:
        ;   1. Waits for this process to exit
        ;   2. Creates a backup of the old .exe
        ;   3. Copies the new .exe in place
        ;   4. Relaunches the application
        ;   5. Cleans up temp files and itself
        batPath := tempDir . "\update.bat"
        pid := DllCall("GetCurrentProcessId", "UInt")

        batContent := ""
        batContent .= "@echo off`r`n"
        batContent .= "echo Waiting for SystemInfo to close...`r`n"
        batContent .= ":waitloop`r`n"
        batContent .= 'tasklist /FI "PID eq ' . pid . '" 2>NUL | find "' . pid . '" >NUL`r`n'
        batContent .= "if not errorlevel 1 (`r`n"
        batContent .= "    timeout /t 1 /nobreak >NUL`r`n"
        batContent .= "    goto waitloop`r`n"
        batContent .= ")`r`n"
        batContent .= 'if exist "' . backupPath . '" del /f "' . backupPath . '"`r`n'
        batContent .= 'rename "' . exePath . '" "' . exeName . '.bak"`r`n'
        batContent .= 'copy /y "' . newExePath . '" "' . exePath . '"`r`n'
        batContent .= 'start "" "' . exePath . '"`r`n'
        batContent .= "timeout /t 2 /nobreak >NUL`r`n"
        batContent .= 'rd /s /q "' . tempDir . '"`r`n'
        batContent .= "exit`r`n"

        f := FileOpen(batPath, "w", "CP0")
        f.Write(batContent)
        f.Close()

        MsgBox(T("upd_success"), T("upd_success_title"), "64")

        ; Launch the batch script hidden and exit
        Run(A_ComSpec . ' /c "' . batPath . '"', tempDir, "Hide")
        ExitApp()

    } catch as e {
        try DirDelete(tempDir, true)
        GuiCtx.btnUpdate.Opt("-Disabled")
        GuiCtx.sb.SetText("")
        MsgBox(T("upd_dl_error") . "`n" . e.Message, T("upd_dl_error_title"), "16")
    }
}

; Recursively search a directory for the first .exe file
FindExeInDir(dir) {
    ; First check top level
    loop files dir . "\*.exe" {
        return A_LoopFileFullPath
    }
    ; Then recurse into subdirectories
    loop files dir . "\*", "D" {
        result := FindExeInDir(A_LoopFileFullPath)
        if (result != "")
            return result
    }
    return ""
}

; Compare two semver-style version strings (e.g., "1.3.0" vs "1.2.1")
; Returns: >0 if a > b, 0 if equal, <0 if a < b
CompareVersions(a, b) {
    partsA := StrSplit(a, ".")
    partsB := StrSplit(b, ".")
    maxLen := Max(partsA.Length, partsB.Length)
    loop maxLen {
        numA := (A_Index <= partsA.Length) ? Integer(partsA[A_Index]) : 0
        numB := (A_Index <= partsB.Length) ? Integer(partsB[A_Index]) : 0
        if (numA != numB)
            return numA - numB
    }
    return 0
}

; ═══════════════════════════════════════════════════════════════
;  EXPORT / CLIPBOARD
; ═══════════════════════════════════════════════════════════════

BuildReportText() {
    global AllData
    sep  := "═══════════════════════════════════════════════════════════════`n"
    thin := "───────────────────────────────────────────────────────────────`n"

    report := sep
    report .= "  " . T("report_title") . "`n"
    report .= "  " . T("generated") . ": " . FormatTime(A_Now, "yyyy-MM-dd  HH:mm:ss") . "`n"
    report .= "  Computer:  " . A_ComputerName . "`n"
    report .= sep . "`n"

    sectionNames := Map(
        "OS", T("sec_os"),
        "CPU", T("sec_cpu"),
        "Memory", T("sec_memory"),
        "GPU", T("sec_gpu"),
        "Disks", T("sec_disks"),
        "Network", T("sec_network"),
        "Mainboard", T("sec_mainboard"),
        "Audio", T("sec_audio"),
        "Printers", T("sec_printers"),
        "Peripherals", T("sec_peripherals")
    )

    order := ["OS", "CPU", "Memory", "GPU", "Disks", "Network", "Mainboard", "Audio", "Printers", "Peripherals"]
    for key in order {
        if (!AllData.Has(key))
            continue
        heading := sectionNames.Has(key) ? sectionNames[key] : key
        report .= thin
        report .= "  ◆  " . heading . "`n"
        report .= thin
        for entry in AllData[key] {
            label := entry[1]
            val   := entry[2]
            if (label = "" && val = "") {
                report .= "`n"
                continue
            }
            if (SubStr(label, 1, 3) = "───") {
                report .= "    " . label . "`n"
                continue
            }
            if (label != "")
                report .= "    " . PadRight(label, 30) . val . "`n"
        }
        report .= "`n"
    }
    report .= sep
    report .= "  " . T("report_end") . "`n"
    report .= sep
    return report
}

PadRight(str, width) {
    while (StrLen(str) < width)
        str .= " "
    return str
}

ExportReport() {
    report := BuildReportText()
    defaultName := "SystemInfo_" . A_ComputerName . "_" . FormatTime(A_Now, "yyyyMMdd_HHmmss") . ".txt"
    filePath := FileSelect("S16", defaultName, T("export_dialog"), T("export_filter"))
    if (filePath = "")
        return
    if (!RegExMatch(filePath, "i)\.txt$"))
        filePath .= ".txt"
    try {
        f := FileOpen(filePath, "w", "UTF-8")
        f.Write(report)
        f.Close()
        MsgBox(T("export_ok") . "`n" . filePath, T("export_ok_title"), "64")
    } catch as e {
        MsgBox(T("export_err") . "`n" . e.Message, T("export_err_title"), "16")
    }
}

CopyToClipboard() {
    A_Clipboard := BuildReportText()
    ToolTip(T("clipboard_ok"))
    SetTimer(() => ToolTip(), -2000)
}
