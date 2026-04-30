% ==============================================================================
% Archivo: BNF.pl
% Módulo: Analizador Sintáctico y Semántico (Gramática Libre de Contexto)
% Descripción: Procesa entradas en lenguaje natural, normaliza el texto, 
% extrae atributos relevantes para el motor de inferencia y determina la 
% intención del usuario (afirmativa o negativa) mediante reglas DCG.
% ==============================================================================

% ------------------------------------------------------------------------------
% procesar_oracion(+String, -Intencion, -AtributosEncontrados)
% Predicado principal. Actúa como pipeline de procesamiento de lenguaje natural (NLP).
% 1. Pasa a minúsculas y elimina tildes.
% 2. Tokeniza la oración separando por espacios y signos de puntuación.
% 3. Extrae los atributos detectados que coinciden con la Base de Datos.
% 4. Rechaza respuestas directas ("sí" o "no") según los requerimientos.
% 5. Filtra palabras desconocidas y delega la evaluación semántica al BNF.
% ------------------------------------------------------------------------------
procesar_oracion(String, Intencion, AtributosEncontrados) :-
    string_lower(String, StringLower),
    quitar_tildes(StringLower, StringSinTildes),
    split_string(StringSinTildes, " ,.?!", " ,.?!", StringList),
    maplist(atom_string, AtomList, StringList),
    
    % Extracción de atributos de interés basándose en el vocabulario del sistema
    findall(A, (member(A, AtomList), es_atributo(A)), AtributosEncontrados),
    
    % Validación de restricción: El sistema NO acepta sí/no de forma directa
    ( (AtomList == [si] ; AtomList == [no]) -> 
        Intencion = rechazo_directo
    ;
        % Se limpian las palabras que no están en el diccionario para no romper el DCG
        filtrar_diccionario(AtomList, TokensLimpios),
        ( oracion(Intencion, TokensLimpios,[]) -> true ; Intencion = desconocido )
    ).

% ------------------------------------------------------------------------------
% Atributos del Sistema
% Define las palabras clave que se cruzan directamente con BD.pl
% ------------------------------------------------------------------------------
es_atributo(A) :- member(A,[tecnologia, matematicas, personas, problemas, rutina, arte, ciencia, naturaleza, escuchar, hablar, casa, hogar, compu, maquinas]).

% ------------------------------------------------------------------------------
% Utilidades de Normalización de Texto
% Permite al sistema ser tolerante a faltas de ortografía con las tildes.
% ------------------------------------------------------------------------------
quitar_tildes(StringIn, StringOut) :-
    string_chars(StringIn, Chars),
    maplist(quitar_tilde_char, Chars, Limpios),
    string_chars(StringOut, Limpios).

quitar_tilde_char(C, R) :- member(C-R,['á'-'a', 'é'-'e', 'í'-'i', 'ó'-'o', 'ú'-'u']), !.
quitar_tilde_char(C, C).

% ------------------------------------------------------------------------------
% filtrar_diccionario(+ListaTokens, -TokensLimpios)
% Descarta cualquier palabra que no pertenezca al diccionario conocido,
% permitiendo que el árbol sintáctico (BNF) se enfoque solo en la estructura base.
% ------------------------------------------------------------------------------
filtrar_diccionario([], []).
filtrar_diccionario([H|T],[H|T2]) :-
    diccionario(H), !, filtrar_diccionario(T, T2).
filtrar_diccionario([_|T], T2) :- filtrar_diccionario(T, T2).

% MEGA DICCIONARIO EXPANDIDO (Corpus Léxico)
diccionario(W) :- member(W,[
    yo, me, te, se, mi, la, las, los, el, un, una, con, por, de, lo, en, a, al, para, o,
    correcto, claro, exactamente, exacto, obvio,
    amo, encanta, encantan, fascina, fascinan, gusta, gustan, intereso, interesa,
    disfruto, prefiero, apasiona, apasionan, apaciona, apacionan, atrae,
    agrada, agradarme, descubriendo, descubro, paso, da, dan,
    odio, detesto, aborrezco, aburre, aburren, desagrada, molesta, molestan,
    soporto, tolero, incomoda, incomodan,
    soy, considero, estoy, estamos,
    mucho, muy, no, si, nada, bastante, demasiado, poco, super, realmente, siempre, nunca, menos, mas, realidad, bien, mal,
    matematicas, matematica, numeros, calculo, tecnologia, aparatos, computadoras, compu, maquinas, tecnologicos,
    personas, gente, publico, humanos, problemas, acertijos, resolver,
    rutina, oficina, repeticion, arte, diseno, dibujo, creatividad,
    ciencia, investigacion, naturaleza, animales, exteriores, plantas, casa, hogar,
    bueno, buena, habil, excelente, experto, experta, genial, habituado, acostumbrado, genio, crack, facil,
    malo, mala, pesimo, pesima, torpe, terrible, dificil,
    escuchar, hablar, aprender, salir, dibujar, estudiar, trabajar, estar
]).

% ==============================================================================
% GRAMÁTICA LIBRE DE CONTEXTO (DCG - Definite Clause Grammars)
% Define cómo se estructuran y agrupan las palabras para formar sintagmas
% y oraciones, deduciendo lógicamente la intención final (si/no).
% ==============================================================================

% Regla raíz: Una oración puede tener un marcador ("sí,", "no,") y un cuerpo.
oracion(Intencion) --> marcador_inicial(Prefijo), cuerpo_oracion(IntencionVerbo), { deducir_intencion(Prefijo, IntencionVerbo, Intencion) }.

% Casos directos de frases cortas
oracion(si) --> sintagma_adverbial(si).
oracion(no) --> sintagma_adverbial(no).
oracion(si) --> [correcto] | [claro] | [exactamente] | [exacto] |[obvio].
oracion(no) --> [no, no].

% Marcadores de inicio de oración
marcador_inicial(si) --> [si] | [correcto] | [claro] | [exactamente] | [exacto].
marcador_inicial(no) --> [no].
marcador_inicial(nulo) -->[].

% Estructura base: Sintagma Nominal + Sintagma Verbal
cuerpo_oracion(I) --> sintagma_nominal, sintagma_verbal(I).
cuerpo_oracion(I) --> sintagma_verbal(I). % Sujeto tácito

% Lógica de deducción: Si la oración empieza con 'no', la intención se fuerza a negativa.
deducir_intencion(no, _, no).
deducir_intencion(_, IntencionVerbo, IntencionVerbo).

% --- SINTAGMAS NOMINALES ---
sintagma_nominal --> pronombre.
sintagma_nominal --> pronombre, pronombre.
sintagma_nominal --> articulo, sustantivo.
sintagma_nominal --> articulo, sustantivo, adjetivo_cualquiera.
sintagma_nominal --> sustantivo.

% Lógica matemática de inversión para negaciones (Ej: "no" + "odio" = "si")
invertir(si, no).
invertir(no, si).

% --- SINTAGMAS VERBALES ---
sintagma_verbal(si) --> verbo_ser, intermedio, adjetivo_positivo, cualquier_cosa.
sintagma_verbal(no) --> verbo_ser, intermedio, adjetivo_negativo, cualquier_cosa.

% Manejo de adverbios de negación modificando el verbo
sintagma_verbal(I) --> adverbio_negacion, pronombre, verbo(V), cualquier_cosa, { invertir(V, I) }.
sintagma_verbal(I) --> adverbio_negacion, verbo(V), cualquier_cosa, { invertir(V, I) }.
sintagma_verbal(I) --> verbo(I), cualquier_cosa.

% ------------------------------------------------------------------------------
% REGLA COMODÍN (Absorción Sintáctica)
% Permite ignorar estructuras complejas al final de la oración que no afectan
% el significado lógico principal (Ej: "amo la tecnología *cuando estoy en casa*").
% ------------------------------------------------------------------------------
cualquier_cosa -->[].
cualquier_cosa --> [_], cualquier_cosa.

intermedio -->[].
intermedio --> articulo.
intermedio --> adverbio_cantidad.
intermedio --> articulo, adverbio_cantidad.
intermedio --> adverbio_cantidad, articulo.

sintagma_adverbial(si) --> [si, mucho] |[si, bastante] | [un, poco] | [mas, o, menos] | [muy, bien].
sintagma_adverbial(no) --> [no, mucho] | [no, nada] |[para, nada] | [no, en, realidad, no] | [en, realidad, no].

% ==============================================================================
% CATEGORÍAS LÉXICAS
% Clasificación de terminales en la gramática.
% ==============================================================================
adverbio_negacion --> [no] |[nada] | [nunca].
pronombre --> [yo] | [me] | [te] | [se] | [mi] | [las] | [la] | [los] | [el] | [lo].
articulo --> [el] | [la] | [los] | [las] |[un] | [una] | [al].

sustantivo --> [matematicas] |[matematica] | [numeros] | [calculo] | [tecnologia] | [aparatos] | [computadoras] | [compu] | [maquinas] | [tecnologicos] |[personas] | [gente] | [publico] | [humanos] | [problemas] |[acertijos] | [rutina] | [oficina] | [repeticion] | [arte] |[diseno] | [dibujo] | [creatividad] | [ciencia] | [investigacion] | [naturaleza] | [animales] | [exteriores] | [plantas] | [casa] | [hogar].

adjetivo_positivo --> [bueno] | [buena] |[habil] | [excelente] | [experto] | [experta] | [genial] |[habituado] | [acostumbrado] | [genio] | [crack] | [bien] | [facil].
adjetivo_negativo --> [malo] | [mala] |[pesimo] | [pesima] | [torpe] | [terrible] | [mal] |[dificil].
adjetivo_cualquiera --> adjetivo_positivo | adjetivo_negativo.
adverbio_cantidad --> [mucho] | [muy] | [bastante] |[demasiado] | [super] | [realmente].

verbo_ser --> [soy] |[considero] | [estoy] | [estamos].

% Los verbos están tipados según su intención intrínseca
verbo(si) --> [amo] | [encanta] | [encantan] |[fascina] | [fascinan] | [gusta] | [gustan] | [intereso] | [interesa] | [disfruto] | [prefiero] | [apasiona] |[apasionan] | [apaciona] | [apacionan] | [atrae] |[agrada] | [agradarme] | [descubriendo] | [descubro] | [da] |[dan].
verbo(no) --> [odio] | [detesto] | [aborrezco] | [aburre] | [aburren] | [desagrada] | [molesta] |[molestan] | [soporto] | [tolero] | [incomoda] | [incomodan].