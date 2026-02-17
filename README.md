# SQL Server CU Updater (Menu+ Edition)

Interaktivní PowerShell nástroj pro kontrolu, instalaci a plánování
Cumulative Updates (CU) pro Microsoft SQL Server.

Tato verze obsahuje:

-   🖥️ Interaktivní menu
-   🌍 Vestavěnou vícejazyčnou podporu (single-file i18n)
-   🔎 Automatickou detekci SQL instancí
-   🌐 Online kontrolu Latest CU z Microsoft Learn
-   ⬇️ Stažení instalačního balíčku
-   🔕 Tichou instalaci
-   🗓️ Plánování na konkrétní datum/čas
-   🕛 Rychlé plánování na půlnoc
-   🧹 Automatické smazání Scheduled Task po dokončení
-   📧 Email notifikaci po dokončení (volitelné)

------------------------------------------------------------------------

## 🚀 Hlavní funkce

1.  Detekce všech nainstalovaných SQL Server instancí
2.  Zjištění aktuální verze (PatchLevel)
3.  Porovnání s Latest CU
4.  Stažení CU z Microsoft Download Center
5.  Tichá instalace (`/quiet` režim)
6.  Naplánování instalace na konkrétní datum/čas
7.  Automatické smazání úlohy po dokončení
8.  Email notifikace s výsledkem (ExitCode)
9.  Přepínání jazyka přímo z menu

------------------------------------------------------------------------

## 📦 Podporované verze SQL Serveru

-   SQL Server 2012
-   SQL Server 2014
-   SQL Server 2016
-   SQL Server 2017
-   SQL Server 2019
-   SQL Server 2022
-   SQL Server 2025

------------------------------------------------------------------------

## ⚙️ Požadavky

-   Windows Server / Windows
-   PowerShell 5.1+
-   Spuštění jako **Administrator**
-   Přístup k internetu

------------------------------------------------------------------------

## 🧠 Spuštění

### Interaktivní režim (doporučeno)

``` powershell
.\SQLupdater_menu_plus.ps1
```

Menu nabídne:

    1) Kontrola
    2) Tichá instalace hned
    3) Naplánovat instalaci (konkrétní datum/čas)
    4) Naplánovat instalaci na půlnoc
    5) Nastavit email (SMTP)
    6) Změnit jazyk
    7) Zobrazit cesty
    0) Konec

------------------------------------------------------------------------

### Non-interactive režim

Okamžitá instalace:

``` powershell
.\SQLupdater_menu_plus.ps1 -InstallNow -Force
```

Naplánování na konkrétní čas:

``` powershell
.\SQLupdater_menu_plus.ps1 -ScheduleAt "2026-02-18 02:15" -Force
```

Naplánování na půlnoc:

``` powershell
.\SQLupdater_menu_plus.ps1 -InstallAtMidnight -Force
```

------------------------------------------------------------------------

## 📧 Email notifikace

Email je volitelný.

Lze nastavit z menu nebo pomocí parametrů:

``` powershell
.\SQLupdater_menu_plus.ps1 `
  -ScheduleAt "2026-02-18 02:15" `
  -SmtpServer smtp.server.local `
  -SmtpPort 587 `
  -SmtpUseSsl `
  -MailFrom sql@firma.cz `
  -MailTo admin@firma.cz `
  -MailUser smtp_user `
  -MailPassword heslo
```

Po dokončení instalace se odešle:

-   Hostname
-   Installer path
-   ExitCode
-   Čas dokončení
-   Cesta k logu

------------------------------------------------------------------------

## 🧹 Automatické mazání úlohy

Naplánovaná úloha:

-   se spustí jako SYSTEM
-   po dokončení se sama smaže
-   smaže i dočasný wrapper skript

Nezůstává žádná trvalá scheduled task.

------------------------------------------------------------------------

## 🌍 Jazyk

Automatická detekce dle Windows UI.

Ruční nastavení:

``` powershell
.\SQLupdater_menu_plus.ps1 -Language cs-CZ
.\SQLupdater_menu_plus.ps1 -Language en-US
```

Nový jazyk lze přidat úpravou `$I18N` hashtable ve skriptu.

------------------------------------------------------------------------

## 📁 Logování

Log soubor:

    C:\ProgramData\SqlCuPatcher\SqlCuPatcher.log

Stažené aktualizace:

    C:\ProgramData\SqlCuPatcher\Downloads\

Wrapper skripty (dočasné):

    C:\ProgramData\SqlCuPatcher\Tasks\

------------------------------------------------------------------------

## 🔒 Parametry instalace

    /quiet
    /IAcceptSQLServerLicenseTerms
    /Action=Patch
    /AllInstances
    /UpdateEnabled=0

Instalace probíhá skrytě na pozadí.

------------------------------------------------------------------------

## ⚠️ Doporučení

-   Před aktualizací proveď zálohu databází
-   U produkčních serverů plánuj maintenance window
-   Po instalaci může být nutný restart služby nebo serveru

------------------------------------------------------------------------

## 🛠 Architektura

1.  Čtení registry SQL instance
2.  Zjištění aktuální verze
3.  Získání Latest CU z Microsoft Learn
4.  Stažení balíčku
5.  Vytvoření wrapper skriptu
6.  Naplánování úlohy přes Task Scheduler
7.  Po dokončení: email + smazání úlohy + smazání wrapperu

------------------------------------------------------------------------
