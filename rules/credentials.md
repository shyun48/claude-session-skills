---
globs: "**/.env,**/credentials/**,**/*.pem,**/*.key"
---

# 인증 파일 보호

.env, credentials/, *.pem, *.key 파일은 읽지도 출력하지도 마라.
키 존재 여부만 확인 가능. 값은 절대 노출 금지.
