import http from 'k6/http';
import { check, sleep } from 'k6';

const perfil = __ENV.PERFIL || 'base';

const perfiles = {
  base: {
    vus: 1,
    duration: '30s',
  },
  carga: {
    stages: [
      { duration: '15s', target: 1 },
      { duration: '15s', target: 5 },
      { duration: '45s', target: 5 },
      { duration: '15s', target: 0 },
    ],
  },
};

if (!perfiles[perfil]) {
  throw new Error('PERFIL debe ser base o carga');
}

export const options = {
  ...perfiles[perfil],
  tags: { perfil },
  summaryTimeUnit: 'ms',
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(95)'],
  thresholds: {
    'http_req_duration{servicio:api}': ['p(95)<2000'],
    'http_req_duration{servicio:cliente}': ['p(95)<2000'],
    'http_req_failed{servicio:api}': ['rate<0.01'],
    'http_req_failed{servicio:cliente}': ['rate<0.01'],
    'http_reqs{servicio:api}': ['count>0'],
    'http_reqs{servicio:cliente}': ['count>0'],
    checks: ['rate>0.99'],
  },
};

export default function () {
  const api = http.post(
    'https://ejercicio5myapigestor-1rp1.onrender.com/buscarProyectos',
    null,
    { tags: { servicio: 'api' }, timeout: '15s' }
  );

  check(api, {
    'API responde 200': (respuesta) => respuesta.status === 200,
  });

  const cliente = http.get(
    'https://ejercicio5cliente-rs8m.onrender.com/login',
    { tags: { servicio: 'cliente' }, timeout: '15s' }
  );

  check(cliente, {
    'Cliente responde 200': (respuesta) => respuesta.status === 200,
  });

  sleep(1);
}