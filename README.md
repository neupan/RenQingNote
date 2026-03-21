# 人情记 (RenQingNote) - 详细设计文档与工程指南

## 1. 项目概述

**人情记 (RenQingNote)** 是一款基于 Flutter 构建的**纯本地**人情往来记账应用。专为管理中国传统“随礼 / 收礼”场景设计。
核心理念：**绝对隐私 (Privacy First)**，所有数据仅存储在手机本地 SQLite 数据库中，无任何网络请求，无需注册账号。

## 2. 核心功能特性

### 2.1 流水管理 (首页)
- **年度汇总**：顶部卡片动态计算并展示本年度的“总收礼”与“总随礼”金额。
- **月度分组列表**：按月份倒序折叠展示流水记录，直观清晰。
- **记录操作**：支持长按单条记录进行编辑或删除。

### 2.2 记账模块 (记一笔)
- **双模切换**：收礼 (收入) 与 随礼 (支出) 快速切换。
- **智能联系人**：支持拼音模糊搜索现有联系人，或直接输入新名字快速创建。
- **事件标签**：预设 9 种常用事件（结婚、满月等），支持自定义扩展。
- **日期与备注**：支持历史日期补录及详细备注说明。

### 2.3 人脉管理 (关系图谱)
- **A-Z 拼音排序**：联系人列表按姓名拼音首字母自动分组排序。
- **智能盈亏计算**：列表页直接展示与该联系人的历史盈亏状态（他欠我 / 我欠他 / 已平账）。
- **个人明细**：点击联系人可查看与其相关的所有历史收支明细及汇总。

### 2.4 系统与安全 (我的)
- **隐私锁**：支持 FaceID / 指纹解锁，应用切入后台自动上锁，保护账单隐私。
- **事件管理**：支持自定义事件类型的增删改，以及拖拽排序。
- **数据备份与恢复**：
  - **CSV 导出**：一键导出所有流水为 `.csv` 格式并调用系统分享。
  - **JSON 备份**：将数据库完整导出为加密/明文 JSON 文件。
  - **JSON 恢复**：支持从本地文件管理器选择备份文件进行全量覆盖恢复。

## 3. 技术架构设计

### 3.1 技术栈选型
- **框架**：Flutter 3.11+ (支持 iOS & Android 双端原生编译)
- **状态管理**：`flutter_riverpod` (响应式、类型安全的状态管理)
- **本地存储**：`sqflite` (SQLite 关系型数据库) + `shared_preferences` (轻量配置)
- **UI 风格**：Material Design 3 (红色系主题色，契合传统喜庆氛围)

### 3.2 核心依赖库
| 包名 | 版本 | 用途说明 |
|------|------|----------|
| `flutter_riverpod` | ^3.3.1 | 全局状态管理、依赖注入 |
| `sqflite` | ^2.4.2 | 核心业务数据持久化 |
| `path_provider` | ^2.1.5 | 获取应用沙盒文档目录 |
| `shared_preferences` | ^2.5.4 | 存储隐私锁开关等轻量级配置 |
| `intl` | ^0.20.2 | 日期格式化、金额数字格式化 |
| `lpinyin` | ^2.0.3 | 中文姓名转拼音，用于 A-Z 分组排序 |
| `local_auth` | ^3.0.1 | FaceID / 指纹生物识别认证 |
| `csv` | ^7.2.0 | 流水数据导出为 CSV 格式 |
| `share_plus` | ^12.0.1 | 调用系统原生分享面板 |
| `file_picker` | ^10.3.10 | 调用系统文件选择器导入备份文件 |

### 3.3 工程目录结构

采用基于功能模块 (Feature-first) 与分层架构混合的目录组织方式：

```text
lib/
├── main.dart                          # 应用入口，初始化 ProviderScope
├── app.dart                           # MaterialApp 配置，全局主题，应用生命周期监听 (隐私锁)
│
├── core/                              # 核心基础层
│   ├── database/                      # 数据库配置
│   │   └── database_helper.dart       # sqflite 单例，建表脚本，预设数据初始化
│   ├── theme/                         # UI 主题
│   │   └── app_theme.dart             # Material 3 主题配置 (深红色系)
│   ├── constants/                     # 全局常量
│   │   ├── default_events.dart        # 预设事件数据
│   │   └── icon_map.dart              # 字符串与 IconData 映射表
│   └── utils/                         # 工具类
│       └── logger.dart                # 日志打印工具
│
├── models/                            # 数据模型层 (Data Models)
│   ├── contact.dart                   # 联系人实体 (id, name, pinyin, memo)
│   ├── event.dart                     # 事件实体 (id, name, icon, sort_order)
│   └── record.dart                    # 流水实体 (id, contact_id, event_id, type, amount)
│
├── repositories/                      # 数据仓库层 (Data Access)
│   ├── contact_repository.dart        # 联系人 CRUD，拼音检索，盈亏聚合查询
│   ├── event_repository.dart          # 事件 CRUD，排序更新，引用校验
│   └── record_repository.dart         # 流水 CRUD，多表 JOIN 查询，年度统计
│
├── providers/                         # 状态管理层 (Riverpod Providers)
│   ├── database_provider.dart         # 提供 Repository 实例的 Provider
│   ├── contact_providers.dart         # 联系人列表、搜索过滤、盈亏计算状态
│   ├── event_providers.dart           # 事件列表、排序状态管理
│   └── record_providers.dart          # 流水列表、年度汇总、联系人明细状态
│
├── pages/                             # 表现层 (UI Pages)
│   ├── home/                          # 根页面
│   │   └── home_page.dart             # 底部导航栏框架 (IndexedStack)
│   ├── transactions/                  # Tab 1: 流水模块
│   │   ├── transactions_page.dart     # 流水首页
│   │   └── widgets/                   # 流水页专属组件 (年度卡片、月度分组)
│   ├── add_record/                    # 记账模块
│   │   ├── add_record_page.dart       # 记一笔表单页
│   │   └── widgets/                   # 表单专属组件 (联系人选择器、事件标签)
│   ├── contacts/                      # Tab 2: 人脉模块
│   │   ├── contacts_page.dart         # 人脉列表页
│   │   └── contact_detail_page.dart   # 联系人详情页
│   └── profile/                       # Tab 3: 我的模块
│       ├── profile_page.dart          # 个人中心首页
│       ├── event_manage_page.dart     # 事件管理页
│       └── backup_restore_page.dart   # 数据备份与恢复页
│
└── widgets/                           # 全局通用组件
    ├── amount_text.dart               # 金额格式化文本组件 (收绿支红)
    └── empty_state.dart               # 通用空数据占位图组件
```

## 4. 数据库设计 (SQLite)

系统核心由三张表构成，采用严格的外键约束保证数据一致性。

### 4.1 实体关系图 (ERD)

```text
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│    contacts     │       │     events      │       │     records     │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──┐   │ id (PK)         │◄──┐   │ id (PK)         │
│ name            │   │   │ name            │   │   │ contact_id (FK) │──┘ (ON DELETE CASCADE)
│ memo            │   │   │ icon            │   │   │ event_id (FK)   │──┘ (ON DELETE RESTRICT)
│ pinyin          │   │   │ sort_order      │   │   │ type (0支/1收)  │
│ created_at      │   │   │ is_preset       │   │   │ amount          │
└─────────────────┘   │   │ created_at      │   │   │ record_date     │
                      │   └─────────────────┘   │   │ note            │
                      └─────────────────────────┴───┴─────────────────┘
```

### 4.2 级联规则说明
- **删除联系人**：触发 `ON DELETE CASCADE`，自动删除该联系人名下的所有流水记录。
- **删除事件类型**：触发 `ON DELETE RESTRICT`，如果该事件已被流水记录引用，则数据库层面拒绝删除，需先清理相关流水。

### 4.3 核心统计算法
- **人脉盈亏计算**：在 `contact_repository.dart` 中通过 SQL 聚合函数实现：
  `SUM(CASE WHEN type = 1 THEN amount ELSE -amount END)` 按 `contact_id` 分组。
- **年度汇总计算**：在 `record_repository.dart` 中通过 SQL 筛选当年数据并按 `type` 分别 `SUM(amount)`。

## 5. 状态管理设计 (Riverpod)

项目采用 `flutter_riverpod` 进行状态管理，遵循单向数据流原则：

1. **Repository 层**：封装纯异步的 SQLite 数据库操作。
2. **Provider 层**：
   - 使用 `FutureProvider` 处理初始化和一次性异步读取（如年度汇总）。
   - 使用 `StateNotifierProvider` 或 `AsyncNotifierProvider` 管理需要频繁增删改查的列表状态（如流水列表、联系人列表）。
3. **UI 层**：使用 `ConsumerWidget` 监听 Provider 状态，根据 `AsyncValue` 的 `data`、`loading`、`error` 状态渲染对应 UI。

数据刷新机制：当执行增删改操作后，通过 `ref.invalidate(provider)` 或 `ref.refresh(provider)` 触发相关列表和统计数据的重新加载，确保 UI 与数据库状态强一致。

## 6. 开发与编译指南

### 6.1 环境要求
- Flutter SDK: `>=3.11.1`
- Dart SDK: `>=3.11.1`
- iOS 编译: Xcode 15+
- Android 编译: Android Studio / Android SDK 34+

### 6.2 本地运行
```bash
# 1. 克隆代码
git clone <repo-url>
cd RenQingNote

# 2. 获取依赖
flutter pub get

# 3. 运行项目 (自动选择连接的设备或模拟器)
flutter run
```

### 6.3 生产包构建
```bash
# 构建 Android APK
flutter build apk --release

# 构建 Android App Bundle (上架 Google Play)
flutter build appbundle --release

# 构建 iOS (需提前在 Xcode 中配置好签名证书)
flutter build ios --release
```

### 6.4 静态代码检查
```bash
flutter analyze
```

## 7. 隐私与数据安全声明

1. **零网络请求**：本应用未集成任何网络请求库（如 http, dio），从物理层面杜绝数据上传。
2. **生物识别**：隐私锁功能调用系统原生 `local_auth` 接口，应用内不存储任何指纹/面容特征数据。
3. **本地沙盒**：数据库文件 (`renqing.db`) 存储于操作系统分配的应用专属沙盒目录中，非 Root/越狱设备无法被其他应用读取。

---
*本文档基于代码库当前状态生成，可作为二次开发、架构评审及维护交接的权威参考。*