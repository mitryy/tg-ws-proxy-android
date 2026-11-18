# TgWsProxy SNI для (старых) Android, v7a build 

[![Build and test](https://github.com/malordin/tg-ws-proxy-android/actions/workflows/trusted-ci.yml/badge.svg)](https://github.com/malordin/tg-ws-proxy-android/actions/workflows/trusted-ci.yml)

Публичный форк [Regstar2/tg-ws-proxy-android](https://github.com/Regstar2/tg-ws-proxy-android) с исправлением TLS SNI для Cloudflare Proxy и выбором Telegram-клиента.

**[Скачать APK из последнего релиза](https://github.com/malordin/tg-ws-proxy-android/releases/latest)** · [Сборки Actions](https://github.com/malordin/tg-ws-proxy-android/actions) · [Сообщить о проблеме](https://github.com/malordin/tg-ws-proxy-android/issues)

Приложение называется **TgWsProxy SNI**, пакет — `io.github.malordin.tgwsproxy`. Оно устанавливается отдельно от оригинала. Требуется Android 8.0+ и устройство ARM64.

## Что изменено в этом форке

### Исправление Cloudflare Proxy

При диагностике 16 ноября 2026 года мобильная сеть открывала TCP к Cloudflare, но TLS-рукопожатие с именами `kws2.<домен>` и `kws4.<домен>` завершалось таймаутом. На тех же IP обычные TLS-имена работали.

Форк разделяет два имени:

| Назначение | Пример |
|---|---|
| TLS SNI | `cakeisalie.co.uk` |
| HTTP Host | `kws2.cakeisalie.co.uk` |
| Путь WebSocket | `/apiws` |

Cloudflare получает HTTP Host нужного датацентра, а TLS использует базовый домен. Исправлены оба frontend — MTProto и SOCKS5 — и встроенная диагностика Cloudflare. Direct и Worker сохраняют прежнее поведение.

Изменение применяется автоматически. **В поле «Маскирующий домен» ничего вводить не нужно:** оно относится к Fake TLS локального MTProto frontend.

Независимые пробы на Pixel 7 Pro подтвердили WebSocket Upgrade для DC2/DC4 и нескольких доменов; после установки первой сборки пользователь подтвердил, что соединение работает. Доступность по-прежнему зависит от сети и внешних серверов.

### Порт 1444

Новый локальный адрес по умолчанию — **`127.0.0.1:1444`**, чтобы не занимать стандартный порт оригинала `1443`. При первом открытии этой версии старое значение по умолчанию `1443` мигрирует на `1444`; другие сохранённые порты сохраняются. Порт можно изменить в настройках.

### Выбор Telegram-клиента

Кнопка **«Применить в Telegram»** открывает системное окно выбора клиента, даже если в Android уже назначен обработчик по умолчанию. В список попадают установленные приложения, обрабатывающие ссылку `tg://`: обычный Telegram, Beta, Plus и другие совместимые клиенты.

Как и в [реализации amurcanov](https://github.com/amurcanov/tg-ws-proxy-android/blob/main/app/src/main/java/com/amurcanov/tgwsproxy/ui/ConnectionTab.kt), используется системный `Intent.createChooser`. В этом форке Android сам определяет все приложения для `tg://`, без фиксированного списка и ограничения `EXTRA_INITIAL_INTENTS` на два дополнительных клиента в Android 10+. [Документация Android](https://developer.android.com/guide/components/intents-filters#ForceChooser).

## Как пользоваться

1. Установите APK со [страницы релизов](https://github.com/malordin/tg-ws-proxy-android/releases/latest).
2. Откройте **TgWsProxy SNI** и включите прокси. По умолчанию используется MTProto → Cloudflare Proxy.
3. Нажмите **«Применить в Telegram»**, выберите нужный клиент и подтвердите подключение внутри него.
4. При обновлении с порта `1443` примените ссылку заново: в ней должен быть порт `1444`.

Настройки оригинального приложения автоматически не импортируются. У нового приложения свой MTProto-секрет, поэтому старая ссылка от другого экземпляра может не подойти. Статус локального listener сам по себе не подтверждает доступность внешнего маршрута — для проверки есть экран диагностики.

## Автоматические сборки и релизы

- Каждый push в `main` и каждый pull request запускают Go-тесты, JVM-тесты и сборку debug APK. APK доступен в артефактах **Build and test**.
- Push тега вида `v1.12.2` запускает **Release**: тесты, сборку подписанного release APK, проверку подписи и публикацию APK вместе с SHA-256 в GitHub Releases.
- Release также можно запустить вручную из Actions, указав уже существующий тег.
- Версия тега должна совпадать с `releaseVersionName` в `app/build.gradle.kts`. Для следующего релиза увеличьте также `releaseVersionCode`, закоммитьте изменения и отправьте новый тег.

```sh
git tag v1.12.2
git push origin v1.12.2
```

Сборка выполняется на GitHub-hosted Ubuntu; собственный runner не нужен. Публикация и ключ подписи недоступны workflow для pull request.

Подпись использует GitHub Actions Secrets: `RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEY_PASSWORD`, `RELEASE_KEY_ALIAS`. В этом репозитории они настроены. Это тот же ключ, которым подписана первая локальная сборка форка, поэтому обновление не требует удаления приложения. Временный файл ключа создаётся только на этапе release-сборки и удаляется после него. В релиз попадают только APK и контрольная сумма.

## Локальная сборка

Нужны JDK 17 или 21, Go 1.25+, Python с зависимостями из `scripts/requirements-ci.txt`, Android SDK 35, Build Tools 34.0.0 и NDK 27.2.12479018.

```sh
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
python -m pip install -r scripts/requirements-ci.txt
sdkmanager 'platforms;android-35' 'build-tools;34.0.0' 'ndk;27.2.12479018'
(cd native/tgwsproxy && go test ./...)
./gradlew :app:testDebugUnitTest :app:assembleDebug
```

Debug APK: `app/build/outputs/apk/debug/app-debug.apk`. Для подписанного release задайте `KEYSTORE_FILE`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` и выполните `./gradlew :app:assembleRelease`.

Ключи подписи, пароли, `secrets/`, локальные настройки и runtime-логи исключены из Git. История и изменения форка проверены сканером секретов; срабатывания в истории upstream относятся к синтетическим тестовым данным. Приватный ключ подписи в исходники и релиз не включается.

## Проверки версии 1.12.2

Локально пройдены 423 JVM-теста, Go-тесты нативного runtime и проверка подписи release APK. YAML workflow проверен actionlint. Gitleaks не нашёл секретов в коммитах этого форка; при проверке полной истории upstream его срабатывания проверены как тестовые значения, включая пример ключа WebSocket из RFC.

## Исходные проекты и лицензия

- [Regstar2/tg-ws-proxy-android](https://github.com/Regstar2/tg-ws-proxy-android) — основа этого форка (версия 1.11.8).
- [amurcanov/tg-ws-proxy-android](https://github.com/amurcanov/tg-ws-proxy-android) — исходный Android-проект и подход к выбору клиента.
- [Flowseal/tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) — исходный проект TG WS Proxy.

Форк распространяется под [GPL-3.0](LICENSE). Дополнительные инструкции находятся в [docs/](docs/).
