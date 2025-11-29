# Build stage
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app

# Copy maven wrapper and pom
COPY .mvn .mvn
COPY mvnw pom.xml ./

# Make mvnw executable
RUN chmod +x mvnw

# Download dependencies
RUN ./mvnw dependency:go-offline -B || true

# Copy source code
COPY src ./src

# Build application (Quarkus creates a quarkus-run.jar in target/quarkus-app/)
RUN ./mvnw clean package -DskipTests -B

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Create non-root user
RUN addgroup -S quarkus && adduser -S quarkus -G quarkus

WORKDIR /app

# Copy the Quarkus app directory structure
COPY --from=build /app/target/quarkus-app/lib/ ./lib/
COPY --from=build /app/target/quarkus-app/*.jar ./
COPY --from=build /app/target/quarkus-app/app/ ./app/
COPY --from=build /app/target/quarkus-app/quarkus/ ./quarkus/

USER quarkus:quarkus

# Expose port (Quarkus default is 8080)
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "/app/quarkus-run.jar"]
