# SQL Server CU Updater (PowerShell -- Menu Edition)

Interaktivní PowerShell nástroj pro kontrolu a instalaci nejnovějších
Cumulative Updates (CU) pro Microsoft SQL Server.

Tato verze obsahuje:

-   🖥️ Interaktivní menu
-   🌍 Vestavěnou vícejazyčnou podporu (single-file i18n)
-   🔎 Automatickou detekci SQL instancí
-   🌐 Online kontrolu Latest CU z Microsoft Learn
-   ⬇️ Stažení instalačního balíčku
-   🔕 Tichou instalaci
-   🕛 Možnost naplánování instalace na půlnoc

------------------------------------------------------------------------

## 🚀 Hlavní funkce

1.  Detekce všech nainstalovaných SQL Server instancí
2.  Zjištění aktuální verze (PatchLevel)
3.  Porovnání s Latest CU
4.  Stažení CU z Microsoft Download Center
5.  Tichá instalace (`/quiet` režim)
6.  Naplánování instalace jako Scheduled Task (běží jako SYSTEM)
7.  Informativní kontrola SQL-related Windows Update položek
8.  Přepínání jazyka přímo z menu

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
.\SQLupdater.ps1
```

Zobrazí se menu:

    1) Kontrola
    2) Tichá instalace hned
    3) Naplánovat instalaci na půlnoc
    4) Změnit jazyk
    5) Zobrazit cesty
    0) Konec

------------------------------------------------------------------------

### Non-interactive režim

Okamžitá instalace:

``` powershell
.\SQLupdater.ps1 -InstallNow -Force
```

Naplánování instalace:

``` powershell
.\SQLupdater.ps1 -InstallAtMidnight -Force
```

------------------------------------------------------------------------

## 🌍 Jazyk

Výchozí jazyk je detekován podle Windows UI.

Ruční nastavení:

``` powershell
.\SQLupdater.ps1 -Language cs-CZ
.\SQLupdater.ps1 -Language en-US
```

Přidání nového jazyka: Stačí doplnit nový blok do `$I18N` hashtable
přímo ve skriptu.

------------------------------------------------------------------------

## 📁 Logování

Log soubor:

    C:\ProgramData\SqlCuPatcher\SqlCuPatcher.log

Stažené aktualizace:

    C:\ProgramData\SqlCuPatcher\Downloads\

------------------------------------------------------------------------

## 🔒 Parametry instalace

Instalace probíhá pomocí:

    /quiet
    /IAcceptSQLServerLicenseTerms
    /Action=Patch
    /AllInstances
    /UpdateEnabled=0

Instalace běží skrytě na pozadí.

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
5.  Instalace nebo plánování pomocí Task Scheduler

------------------------------------------------------------------------

## 👨‍💻 Autor

Interní nástroj pro automatizaci SQL Server patch managementu.

------------------------------------------------------------------------

## 📜 Licence

Doporučeno doplnit MIT/GPL dle potřeby před veřejným publikováním.
