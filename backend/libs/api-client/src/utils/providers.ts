// import { FactoryProvider } from '@nestjs/common';
// import { AxiosInstance } from 'axios';

// export function injectApiProvider<T>(
//   ApiClass: new (
//     configuration?: Configuration,
//     basePath?: string,
//     axios?: AxiosInstance,
//   ) => T,
// ): FactoryProvider<T> {
//   return {
//     provide: ApiClass,
//     inject: [HttpService],
//     useFactory: (httpService: HttpService) => {
//       const config = new Configuration({
//         basePath: process.env.SSO_SERVICE_URL || 'http://localhost:5051',
//       });
//       return new ApiClass(config, config.basePath, httpService.axiosRef);
//     },
//   };
// }
