# ---------- Stage 1 : Build ----------
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

COPY . .

RUN mvn clean package -DskipTests

# ---------- Stage 2 : Runtime ----------
FROM eclipse-temurin:21-jre

WORKDIR /app

RUN useradd -m springuser

COPY --from=builder /app/target/*.jar app.jar

USER springuser

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]