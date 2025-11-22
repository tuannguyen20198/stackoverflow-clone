import { FactoryProvider } from '@nestjs/common';
import { Configuration } from '../client/generated/configuration';

export function injectApiProvider<T>(
    ApiClass: new (configuration?: Configuration, basePath?: string) => T,
): FactoryProvider<T> {
  const basePath = process.env.API_SERVICE_URL || 'http://localhost:5050';
  return {
    provide: ApiClass,
    useFactory: () => {
      const config = new Configuration({
        basePath: process.env.API_SERVICE_URL || 'http://localhost:5050',
      });
      return new ApiClass(config, config.basePath);
    },
  };
}
