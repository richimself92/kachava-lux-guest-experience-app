import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import 'reflect-metadata';
import { AppModule } from './app.module';
import { assertAdminIdentityConfigured } from './common/config/admin-identity';
import { assertFirestoreTarget } from './common/config/runtime-flags';
import { assertProductionSecrets } from './common/config/runtime-secrets';
import { GlobalHttpExceptionFilter } from './common/filters/global-http-exception.filter';
import { ResponseTransformInterceptor } from './common/interceptors/response-transform.interceptor';

/**
 * Cloud Run terminates TLS at one Google front-end hop; trust exactly that hop for req.ip.
 * This assumes clients reach the service directly on its run.app URL (Google Front End only).
 * If a load balancer / API gateway / CDN is ever placed in front, req.ip becomes that proxy's
 * address (or a client-spoofable X-Forwarded-For entry): this value MUST be revisited then,
 * because per-IP throttling depends on it.
 */
const TRUSTED_PROXY_HOPS = 1;

export function configureApp(app: NestExpressApplication): void {
  app.set('trust proxy', TRUSTED_PROXY_HOPS);
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
}

export async function bootstrap(): Promise<void> {
  assertProductionSecrets();
  assertAdminIdentityConfigured();
  assertFirestoreTarget();
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  configureApp(app);
  const port = Number(process.env.PORT || 8080);
  await app.listen(port);
}

if (require.main === module) {
  void bootstrap();
}
