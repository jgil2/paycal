# PayCal - iOS 17 Paycheck & Bill Tracker

PayCal is a native iOS 17 SwiftUI application built with SwiftData and local notifications. Designed for lightweight, privacy-focused financial item tracking without servers or 3rd-party dependencies.

---

## 🚀 How to Build on Windows (No Mac or Xcode Required)

### Step 1: Upload to GitHub
1. Click **Download Full Repo (.zip)** at the top right of this web tool.
2. Extract the downloaded zip file on your Windows computer.
3. Create a **New Repository** on [GitHub.com](https://github.com).
4. Upload all files from the extracted folder to your new GitHub repository.

---

### Step 2: Download the Unsigned IPA Artifact
1. Go to your repository on GitHub.
2. Click on the **Actions** tab.
3. Select the latest workflow run named **Build PayCal Unsigned IPA**.
4. Once the build completes (green checkmark), scroll down to **Artifacts**.
5. Download **PayCal-Unsigned-IPA** (which contains `PayCal.ipa`).

---

### Step 3: Sideload onto your iPhone with Sideloadly
1. Download and install **Sideloadly** on Windows ([sideloadly.io](https://sideloadly.io)).
2. Plug your iPhone into your PC via USB and unlock it.
3. Open Sideloadly:
   - Drag and drop `PayCal.ipa` into the IPA box.
   - Enter your Apple ID email.
   - Click **Start** to install PayCal on your iPhone.
4. On your iPhone, open **Settings -> General -> VPN & Device Management**, tap your Apple ID, and tap **Trust**.

---

## 🛠 Features
- **30-Day Cash Flow Dashboard**: Live calculation of income, bills, and expected balance.
- **Repeat Schedules**: Support for Weekly, Biweekly, Monthly, and Yearly recurring items.
- **Auto Capped Notifications**: Intelligently schedules only the next 2 occurrences per item and limits local alerts strictly to iOS's 64 notification ceiling.
- **Calendar View**: Custom month grid displaying days with scheduled bills or paychecks.
