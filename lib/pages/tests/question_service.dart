import 'dart:math';

class QuestionService {
  static final Random _random = Random();

  static List<Map<String, dynamic>> getAttentionVisualQuestions(int count) {
    List<Map<String, dynamic>> pool = [
      {
        'question': 'Encuentra la letra "A" entre las siguientes opciones:',
        'options': ['B', 'C', 'A', 'D', 'E'],
        'correct': 2,
      },
      {
        'question': 'Selecciona el color ROJO:',
        'options': ['🔵 Azul', '🟢 Verde', '🟡 Amarillo', '🔴 Rojo', '🟣 Morado'],
        'correct': 3,
      },
      {
        'question': 'Encuentra la figura que es diferente:',
        'options': ['⬜', '⬜', '🔴', '⬜', '⬜'],
        'correct': 2,
      },
      {
        'question': '¿Qué otra palabra se puede usar para decir "hogar"?',
        'options': ['Casa', 'Caza', 'Cama', 'Cosa', 'Cisa'],
        'correct': 0,
      },
      {
        'question': 'Encuentra el número que no es par:',
        'options': ['2', '4', '6', '8', '7'],
        'correct': 4,
      },
      {
        'question': 'Selecciona la fruta que es roja:',
        'options': ['🍌 Plátano', '🍏 Manzana verde', '🍓 Fresa', '🍊 Naranja'],
        'correct': 2,
      },
      {
        'question': '¿Cuál de estos es un animal doméstico?',
        'options': ['🦁 León', '🐘 Elefante', '🐕 Perro', '🦈 Tiburón'],
        'correct': 2,
      },
      {
        'question': 'Encuentra el símbolo que representa la paz:',
        'options': ['⚡', '☮️', '☣️', '☢️'],
        'correct': 1,
      },
      {
        'question': '¿Cuál es el color del cielo en un día despejado?',
        'options': ['Negro', 'Verde', 'Azul', 'Rojo'],
        'correct': 2,
      },
      {
        'question': 'Selecciona el número más grande:',
        'options': ['45', '89', '12', '99'],
        'correct': 3,
      },
      {
        'question': '¿Qué objeto se usa para escribir?',
        'options': ['🍴 Tenedor', '✏️ Lápiz', '👟 Zapato', '🔑 Llave'],
        'correct': 1,
      },
      {
        'question': 'Encuentra la palabra mal escrita:',
        'options': ['Árbol', 'Canción', 'Reloj', 'Zappato'],
        'correct': 3,
      },
      {
        'question': 'Selecciona el transporte que vuela:',
        'options': ['🚗 Coche', '🚲 Bicicleta', '✈️ Avión', '🚢 Barco'],
        'correct': 2,
      },
    ];

    pool.shuffle(_random);
    return pool.take(count).toList();
  }

  static List<Map<String, dynamic>> getEmotionQuestions(int count) {
    List<Map<String, dynamic>> pool = [
      {
        'question': 'Cuando enfrentas un problema difícil, ¿cómo sueles reaccionar?',
        'options': [
          'Me siento abrumado y evito el problema',
          'Busco ayuda inmediatamente',
          'Analizo calmadamente las opciones',
          'Me enojo y frustro fácilmente'
        ]
      },
      {
        'question': '¿Cómo te sientes cuando logras un objetivo importante?',
        'options': [
          'Contento, pero pronto busco el siguiente resto',
          'Extremadamente feliz y celebró el logro',
          'Satisfecho, pero mantengo la calma',
          'Aliviado de que haya terminado'
        ]
      },
      {
        'question': 'Cuando alguien te critica, ¿cuál es tu reacción típica?',
        'options': [
          'Me lo tomo personalmente y me afecta',
          'Escucho y reflexiono sobre la crítica',
          'Me defiendo y contraataco',
          'Pido más información para entender'
        ]
      },
      {
        'question': '¿Cómo manejas el estrés en situaciones de presión?',
        'options': [
          'Me mantengo calmado y organizado',
          'Me pongo nervioso pero sigo adelante',
          'Me bloqueo y no puedo pensar claro',
          'Me enojo con los demás'
        ]
      },
      {
        'question': 'Cuando ves a alguien pasando por un momento difícil, ¿qué haces?',
        'options': [
          'Me acerco y ofrezco mi ayuda',
          'Siento empatía pero no me involucro',
          'No sé cómo reaccionar y me alejo',
          'Comparto una experiencia similar'
        ]
      },
      {
        'question': '¿Qué haces cuando sientes mucha alegría?',
        'options': [
          'Lo comparto con todos',
          'Me lo guardo para mí',
          'Sonrío pero trato de ser discreto',
          'Me pongo a saltar y gritar'
        ]
      },
      {
        'question': 'Si cometes un error en público, ¿cómo te sientes?',
        'options': [
          'Me muero de vergüenza',
          'Me río de mí mismo',
          'Trato de ignorarlo',
          'Pido disculpas y trato de corregirlo'
        ]
      },
      {
        'question': '¿Cómo prefieres pasar tu tiempo libre cuando estás cansado emocionalmente?',
        'options': [
          'Solo y en silencio',
          'Con mis amigos más cercanos',
          'Haciendo alguna actividad física',
          'Viendo una película o serie'
        ]
      },
      {
        'question': 'Cuando alguien te cuenta un secreto importante, ¿qué sientes?',
        'options': [
          'Una gran responsabilidad',
          'Confianza y cercanía',
          'Nervios por si se me escapa',
          'Orgullo por ser digno de confianza'
        ]
      },
      {
        'question': '¿Cómo reaccionas ante un cambio inesperado en tus planes?',
        'options': [
          'Me adapto rápido y busco alternativas',
          'Me molesto un poco pero lo acepto',
          'Me frustro mucho y me cuesta cambiar',
          'Me da igual, me dejo llevar'
        ]
      }
    ];

    pool.shuffle(_random);
    return pool.take(count).toList();
  }

  static List<Map<String, dynamic>> getMathQuestions(String operator, int count) {
    List<Map<String, dynamic>> questions = [];
    
    for (int i = 0; i < count; i++) {
      int a, b, correct;
      String opStr = operator;
      
      if (operator == 'mix') {
        final ops = ['+', '-', '×', '÷'];
        opStr = ops[_random.nextInt(ops.length)];
      }

      switch (opStr) {
        case '+':
          a = _random.nextInt(50) + 1;
          b = _random.nextInt(50) + 1;
          correct = a + b;
          break;
        case '-':
          a = _random.nextInt(50) + 20;
          b = _random.nextInt(a - 5) + 1;
          correct = a - b;
          break;
        case '×':
          a = _random.nextInt(12) + 1;
          b = _random.nextInt(12) + 1;
          correct = a * b;
          break;
        case '÷':
          b = _random.nextInt(10) + 1;
          correct = _random.nextInt(10) + 1;
          a = b * correct;
          break;
        default:
          a = 10; b = 5; correct = 15;
      }

      List<int> options = [correct];
      while (options.length < 4) {
        int wrong = correct + (_random.nextInt(10) - 5);
        if (wrong != correct && wrong > 0 && !options.contains(wrong)) {
          options.add(wrong);
        }
      }
      options.shuffle(_random);

      questions.add({
        'question': '$a $opStr $b = ?',
        'options': options.map((e) => e.toString()).toList(),
        'correct': options.indexOf(correct),
      });
    }
    
    return questions;
  }
}
