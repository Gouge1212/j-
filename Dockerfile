# 构建参数
ARG PROJECT_TYPE=java

# 前端构建阶段（注：实际为 Vue2 + vue-cli 工程，位于 ruoyi-ui/ 子目录，
# 2026-10-01 修复：原在本阶段直接在仓库根目录 npm install，根目录无 package.json 必然失败）
FROM node:16-alpine as vue3-builder
WORKDIR /app
COPY ruoyi-ui/package*.json ./
RUN npm install --no-audit --no-fund
COPY ruoyi-ui/ ./
RUN npm run build

# Java项目构建阶段（2026-10-01 修复：原 ./mvnw 在仓库中不存在且 openjdk 镜像不含 maven，
# 构建必然失败；改用 maven 官方镜像 + mvn 命令）
FROM maven:3.9-eclipse-temurin-17 as java-builder
WORKDIR /app
COPY . .
RUN mvn -B clean package -DskipTests

# 基础镜像选择
FROM nginx:alpine as vue3-runtime
COPY --from=vue3-builder /app/dist /usr/share/nginx/html
# 2026-10-01 修复：nginx 原生不展开环境变量，静态 COPY 的 default.conf 中
# proxy_pass ${MASTER_URL} 无法工作；改用官方镜像模板机制，
# 启动时 envsubst 渲染 /etc/nginx/templates/*.template -> /etc/nginx/conf.d/
COPY nginx.conf /etc/nginx/templates/default.conf.template

FROM openjdk:17-jdk-alpine as java-runtime
WORKDIR /app
COPY --from=java-builder /app/ruoyi-admin/target/ruoyi-admin.jar /app/app.jar

# 最终镜像
FROM ${PROJECT_TYPE}-runtime

# 维护者信息
MAINTAINER ruoyi

# 构建参数
ARG MASTER_URL=http://localhost:8080
ARG MASTER_API_KEY=

# 环境变量
ENV TZ=Asia/Shanghai
ENV MASTER_URL=${MASTER_URL}
ENV MASTER_API_KEY=${MASTER_API_KEY}

# 暴露端口
EXPOSE 8080

# 启动命令
CMD if [ "${PROJECT_TYPE}" = "vue3" ]; then nginx -g "daemon off;"; else java -Xms256m -Xmx512m -jar app.jar; fi
