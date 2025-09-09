# 安全策略 | zh-cn
我们会对以下版本的项目提供安全更新：
- 主分支（`main` / `master`）  
- 最近的稳定发布版本  

旧版本通常不会再收到安全修复，请尽快升级到受支持版本。

## 报告漏洞
如果你发现了潜在的安全漏洞，请不要在公共 Issue 中直接披露。  
请通过以下方式报告：
- 发送邮件至：**BINGO-COMPUTER@outlook.com**  
- 或使用 GitHub 的 **Security Advisories** 功能提交报告  

我们会在 **48 小时内确认**，并在 **7 天内给出初步反馈**。  
在漏洞修复并发布前，请不要公开讨论相关细节。

## 漏洞处理流程
1. 报告人提交漏洞信息  
2. BinGo Lab 确认并复现问题  
3. 制定修复方案并进行测试  
4. 发布安全补丁和通报  
5. 在发布后感谢报告者（如报告人同意署名）

## 安全最佳实践
如果你在使用或二次开发本项目，请注意：
- 始终使用 **项目推荐的 Qt 与 C++ 编译器版本**   
- 在构建时启用编译器安全选项（如 `-fstack-protector-strong`，`-D_FORTIFY_SOURCE=2`）  
- 避免使用不安全的函数（如 `strcpy`, `sprintf` 等）  
- 定期检查依赖库的安全公告  
- 部署时启用沙箱、ASLR、DEP 等操作系统安全机制
- 始终使用官方推荐的最佳安全实践



# Security Policy | en-us
We currently provide security updates for:
- The main branch (`main` / `master`)  
- The latest stable release  

Older releases generally do not receive security patches. Please upgrade to a supported version.

## Reporting a Vulnerability
If you discover a potential security issue, **do not disclose it publicly** in Issues or Discussions.  
Please report it via:
- Email: **BINGO-COMPUTER@outlook.com**  
- GitHub **Security Advisories**  

We will acknowledge your report within **48 hours**, and provide an initial response within **7 days**.  
Please keep the details private until a fix is released.

## Vulnerability Handling Process
1. Vulnerability report is submitted  
2. BinGo Lab verifies and reproduces the issue  
3. Fix is developed and tested  
4. Security patch and advisory are published  
5. Reporter is credited (if they wish to be acknowledged)

## Security Best Practices
If you are using or extending this project:
- Always use the **project-recommended versions of Qt and the C++ compiler**  
- Enable compiler hardening flags (e.g. `-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`)  
- Avoid unsafe functions (e.g. `strcpy`, `sprintf`)  
- Regularly check advisories for dependent libraries  
- Enable OS-level protections (sandboxing, ASLR, DEP, etc.) when deploying
- Always follow the officially recommended best security practices
