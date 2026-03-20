# 人情记 (RenQingNote)

一款**纯本地**的人情往来记账 APP，专为管理中国传统"随礼 / 收礼"场景而设计。所有数据仅存储在手机本地，无需注册账号，无需网络，隐私安全。

## 功能概览

| 模块 | 功能 |
|------|------|
| **流水 (首页)** | 年度收支汇总卡片，按月分组的往来流水列表，长按可编辑 / 删除 |
| **记一笔** | 收礼 / 随礼切换，金额输入，联系人模糊搜索 + 快速新建，事件标签选择 + 快速新建，日期选择，备注 |
| **人脉** | 联系人 A-Z 拼音排序，每人旁显示盈亏标签（他欠我 / 我欠他 / 已平账），点击查看历史明细 |
| **事件管理** | 自定义事件类型（增删改），拖拽排序，图标选择，预设 9 种常用事件 |
| **隐私锁** | 支持 FaceID / 指纹解锁，后台切换自动上锁 |
| **数据管理** | CSV 导出 + 系统分享，JSON 全量备份，JSON 覆盖恢复 |

## 技术栈

- **Flutter 3.41+** — iOS & Android 双端
- **Riverpod** — 状态管理
- **sqflite** — 本地 SQLite 数据库
- **Material Design 3** — 现代 UI 风格

## 工程结构

```
lib/
├── main.dart                          # 入口，ProviderScope
├── app.dart                           # MaterialApp，主题，隐私锁生命周期
│
├── core/
│   ├── database/
│   │   └── database_helper.dart       # sqflite 单例，建表，预设事件初始化
│   ├── theme/
│   │   └── app_theme.dart             # Material Design 3 主题 (红色系种子色)
│   └── constants/
│       ├── default_events.dart        # 9 种预设事件定义
│       └── icon_map.dart              # 图标名称 -> IconData 映射
│
├── models/
│   ├── contact.dart                   # 联系人模型 (name, memo, pinyin)
│   ├── event.dart                     # 事件类型模型 (name, icon, sort_order)
│   └── record.dart                    # 流水记录模型 (contact_id, event_id, type, amount)
│
├── repositories/
│   ├── contact_repository.dart        # 联系人 CRUD + 模糊搜索 + 盈亏聚合查询
│   ├── event_repository.dart          # 事件 CRUD + 排序更新 + 引用计数检查
│   └── record_repository.dart         # 流水 CRUD + 年度汇总 + JOIN 查询
│
├── providers/
│   ├── database_provider.dart         # DatabaseHelper / Repository Providers
│   ├── contact_providers.dart         # 联系人列表 + 盈亏数据 Providers
│   ├── event_providers.dart           # 事件列表 Provider + 增删改排序
│   └── record_providers.dart          # 流水列表 + 年度汇总 + 联系人流水 Providers
│
├── pages/
│   ├── home/
│   │   └── home_page.dart             # 底部导航栏 (3 Tab + 中间 FAB)
│   ├── transactions/
│   │   ├── transactions_page.dart     # Tab 1: 流水首页
│   │   └── widgets/
│   │       ├── year_summary_card.dart # 年度收支汇总卡片
│   │       └── monthly_group.dart     # 按月分组流水列表项
│   ├── add_record/
│   │   ├── add_record_page.dart       # 记一笔 / 编辑记录页
│   │   └── widgets/
│   │       ├── contact_picker.dart    # 联系人搜索选择器
│   │       └── event_tag_selector.dart# 事件标签选择器
│   ├── contacts/
│   │   ├── contacts_page.dart         # Tab 2: 人脉列表 (A-Z 分组 + 盈亏标签)
│   │   └── contact_detail_page.dart   # 联系人详情 (汇总 + 历史流水)
│   └── profile/
│       ├── profile_page.dart          # Tab 3: 我的 (隐私锁、事件管理、数据管理入口)
│       ├── event_manage_page.dart     # 事件类型管理 (拖拽排序、增删改)
│       └── backup_restore_page.dart   # CSV 导出 / JSON 备份 / JSON 恢复
│
└── widgets/
    ├── amount_text.dart               # 金额显示组件 (收入绿色 / 支出红色)
    └── empty_state.dart               # 通用空状态占位组件
```

## 数据库设计

三张核心表，通过外键关联：

```
┌──────────┐       ┌──────────┐       ┌──────────┐
│ contacts │       │  events  │       │ records  │
├──────────┤       ├──────────┤       ├──────────┤
│ id (PK)  │◄──┐   │ id (PK)  │◄──┐   │ id (PK)  │
│ name     │   │   │ name     │   │   │ contact_id│──┘ (CASCADE)
│ memo     │   │   │ icon     │   │   │ event_id │──┘ (RESTRICT)
│ pinyin   │   │   │sort_order│   │   │ type     │
│created_at│   │   │is_preset │   │   │ amount   │
└──────────┘   │   │created_at│   │   │record_date│
               │   └──────────┘   │   │ note     │
               └──────────────────┴───┴──────────┘
```

- 删除联系人 → 级联删除其所有流水记录 (CASCADE)
- 删除事件类型 → 若有流水引用则禁止删除 (RESTRICT)

## 环境要求

- Flutter SDK >= 3.11 (Dart >= 3.11)
- Xcode >= 15 (iOS 编译)
- Android SDK >= 21 (Android 编译)

## 编译与运行

### 1. 克隆项目

```bash
git clone <repo-url>
cd RenQingNote
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行 (Debug 模式)

```bash
# iOS 模拟器
flutter run -d ios

# Android 模拟器 / 设备
flutter run -d android

# 自动选择已连接设备
flutter run
```

### 4. 静态分析

```bash
flutter analyze
```

### 5. 构建发布包

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 核心依赖

| 包名 | 用途 |
|------|------|
| `sqflite` | SQLite 本地数据库 |
| `path_provider` | 获取应用文档目录 |
| `flutter_riverpod` | 响应式状态管理 |
| `intl` | 日期 / 数字国际化格式 |
| `lpinyin` | 中文姓名转拼音 (A-Z 排序) |
| `local_auth` | FaceID / 指纹生物识别 |
| `csv` | CSV 格式编码 |
| `share_plus` | 系统分享面板 |
| `file_picker` | 文件选择器 (JSON 恢复) |
| `shared_preferences` | 轻量键值存储 (隐私锁开关) |

## 许可证

私有项目，未公开发布。
