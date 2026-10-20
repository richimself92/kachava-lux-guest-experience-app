import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import 'reflect-metadata';
import { AppModule } from './app.module';
import { GlobalHttpExceptionFilter } from './common/filters/global-http-exception.filter';
import { ResponseTransformInterceptor } from './common/interceptors/response-transform.interceptor';

export async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api/v1');
  app.enableCors({
    origin: process.env.CORS_ALLOWED_ORIGINS
      ? process.env.CORS_ALLOWED_ORIGINS.split(',')
      : true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Guest-Token',
      'X-StepUp-Session',
      'X-StepUp-Token',
    ],
    credentials: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );
  app.useGlobalInterceptors(new ResponseTransformInterceptor());
  app.useGlobalFilters(new GlobalHttpExceptionFilter());

  const port = Number(process.env.PORT || 8080);
  await app.listen(port);
}

if (require.main === module) {
  void bootstrap();
}
