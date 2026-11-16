import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Respostas reais do CPTEC/INPE (capturadas em 16/11/2026).
const xmlCidadesSaoPaulo =
    "<?xml version='1.0' encoding='ISO-8859-1'?><cidades>"
    '<cidade><nome>São Paulo</nome><uf>SP</uf><id>244</id></cidade>'
    '<cidade><nome>São Paulo das Missões</nome><uf>RS</uf><id>5019</id></cidade>'
    '<cidade><nome>São Paulo de Olivença</nome><uf>AM</uf><id>5020</id></cidade>'
    '<cidade><nome>São Paulo do Potengi</nome><uf>RN</uf><id>5021</id></cidade>'
    '</cidades>';

const xmlCidadesVazio =
    "<?xml version='1.0' encoding='ISO-8859-1'?><cidades></cidades>";

const xmlPrevisaoSaoPaulo =
    "<?xml version='1.0' encoding='ISO-8859-1'?><cidade>"
    '<nome>São Paulo</nome><uf>SP</uf><atualizacao>2026-11-16</atualizacao>'
    '<previsao><dia>2026-11-17</dia><tempo>pn</tempo><maxima>27</maxima><minima>18</minima><iuv>0.0</iuv></previsao>'
    '<previsao><dia>2026-11-18</dia><tempo>c</tempo><maxima>30</maxima><minima>19</minima><iuv>0.0</iuv></previsao>'
    '<previsao><dia>2026-11-19</dia><tempo>ps</tempo><maxima>29</maxima><minima>23</minima><iuv>11.0</iuv></previsao>'
    '<previsao><dia>2026-11-20</dia><tempo>t</tempo><maxima>31</maxima><minima>23</minima><iuv>7.5</iuv></previsao>'
    '</cidade>';

/// O que o CPTEC devolve para um código que não existe.
const xmlPrevisaoNula =
    "<?xml version='1.0' encoding='ISO-8859-1'?><cidade>"
    '<nome>null</nome><uf>null</uf><atualizacao>null</atualizacao>'
    '<previsao><dia>null</dia><tempo>null</tempo><maxima>null</maxima><minima>null</minima><iuv>0.0</iuv></previsao>'
    '<previsao><dia>null</dia><tempo>null</tempo><maxima>null</maxima><minima>null</minima><iuv>0.0</iuv></previsao>'
    '</cidade>';

/// Resposta HTTP com o corpo codificado em ISO-8859-1, como o CPTEC envia.
http.Response respostaLatin1(String xml, [int status = 200]) => http.Response.bytes(
      latin1.encode(xml),
      status,
      headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
    );

/// Cliente falso que responde conforme o caminho da URL.
MockClient clienteFalso({
  String cidades = xmlCidadesSaoPaulo,
  String previsao = xmlPrevisaoSaoPaulo,
  List<Uri>? requisicoes,
}) =>
    MockClient((req) async {
      requisicoes?.add(req.url);
      if (req.url.path.contains('listaCidades')) return respostaLatin1(cidades);
      return respostaLatin1(previsao);
    });
