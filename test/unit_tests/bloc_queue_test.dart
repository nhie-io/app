import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import 'package:never_have_i_ever/blocs/statement_bloc.dart';
import 'package:never_have_i_ever/models/category.dart';
import 'package:never_have_i_ever/models/category_icon.dart';
import 'package:never_have_i_ever/models/statement.dart';
import 'package:never_have_i_ever/services/statement_api_provider.dart';

import '../setup.dart';

class MockClient extends Mock implements http.Client {}

Statement next(Iterator<Statement> iterator) {
  iterator.moveNext();
  return iterator.current;
}

main() {
  defaultSetup();
  final client = MockClient();
  final category = CategoryIcon(
      name: Category.harmless,
      selectedImageUri: 'images/mojito.png',
      unselectedImageUri: 'images/mojito_gray.png',
      selected: true);

  test('return statements not in queue iii', () async {
    Queue<String> apiResponse = Queue.from([
      '{"ID":"e1ce4647-c87d-4a0f-a91b-8db204e8889d","statement":"Never have I ever told somebody that I love his/her body.","category":"harmless"}',
      '{"ID":"e1ce4647-c87d-4a0f-a91b-8db204e8889d","statement":"Never have I ever told somebody that I love his/her body.","category":"harmless"}',
      '{"ID":"ec2a37e7-da79-44dc-b292-a5c343c0eaa8","statement":"Never have I ever forgotten to buy a present.","category":"harmless"}',
    ]);

    Iterable<Statement> statementIterable = Iterable.castFrom([
      Statement(
        uuid: null,
        text: 'Tap to start playing',
        category: null,
      ),
      Statement(
        uuid: 'e1ce4647-c87d-4a0f-a91b-8db204e8889d',
        text: 'Never have I ever told somebody that I love his/her body.',
        category: Category.harmless,
      ),
      Statement(
        uuid: 'ec2a37e7-da79-44dc-b292-a5c343c0eaa8',
        text: 'Never have I ever forgotten to buy a present.',
        category: Category.harmless,
      )
    ]);
    Iterator<Statement> expectedResponse = statementIterable.iterator;

    StatementApiProvider.client = client;
    when(client.get(
            'https://api.neverhaveiever.io/v1/statements/random?category[]=harmless'))
        .thenAnswer((_) async {
      return http.Response(apiResponse.removeFirst(), 200);
    });

    expectLater(bloc.statement, emits(next(expectedResponse)));

    await bloc.fetchStatement([category]);
    await bloc.fetchStatement([category]);
    await bloc.fetchStatement([category]);

    // clean up
    bloc.dispose();
  });

  test('max api calls', () async {
    final answer =
        '{"ID":"e1ce4647-c87d-4a0f-a91b-8db204e8889d","statement":"Never have I ever told somebody that I love his/her body.","category":"harmless"}';
    Iterable<Statement> statementIterable = Iterable.castFrom([
      Statement(
        uuid: null,
        text: 'Tap to start playing',
        category: null,
      ),
      Statement(
        uuid: 'e1ce4647-c87d-4a0f-a91b-8db204e8889d',
        text: 'Never have I ever told somebody that I love his/her body.',
        category: Category.harmless,
      ),
      Statement(
        uuid: null,
        text: 'Please try again',
        category: null,
      )
    ]);
    Iterator<Statement> expectedResults = statementIterable.iterator;

    StatementApiProvider.client = client;
    when(client.get(
            'https://api.neverhaveiever.io/v1/statements/random?category[]=harmless'))
        .thenAnswer((_) async {
      return http.Response(answer, 200);
    });

    expectLater(bloc.statement, emits(next(expectedResults)));

    await bloc.fetchStatement([category]);
    await bloc.fetchStatement([category]);
    await bloc.fetchStatement([category]);

    // clean up
    bloc.dispose();
  });

  test('full statement queue', () async {
    Queue<Statement> statements;
    final jsonData = json.decode(getResponses());
    statements = Queue<Statement>.from(
        jsonData.map((element) => Statement.fromMap(element)));
    Statement first = statements.first;

    StatementApiProvider.client = client;
    when(client.get(
            'https://api.neverhaveiever.io/v1/statements/random?category[]=harmless'))
        .thenAnswer((_) async {
      var statement;
      if (statements.isNotEmpty) {
        statement = statements.removeFirst();
      } else {
        statement = first;
      }

      return http.Response(
          '{"ID":"${statement.uuid}",'
          '"statement":"${statement.text}",'
          '"category":"'
          '${statement.category.toString().substring(statement.category.toString().indexOf('.') + 1)}"}',
          200);
    });

    // The limit needs to be 51 because the first id removed on a full queue is null from the call to action statement.
    for (var i = 0; i <= 51; i++) {
      await bloc.fetchStatement([category]);
    }

    expectLater(bloc.statement, emits(first));
    await bloc.fetchStatement([category]);

    // clean up
    bloc.dispose();
  });
}

getResponses() {
  return r'''
    [
      {
        "ID":"fc39997b-0a74-44ad-9657-15ad0e764a92",
        "statement":"Never have I ever really sticked to a New Year's resolution.",
        "category":"harmless"
      },
      {
        "ID":"8ac9c16b-831e-4241-b279-ac1c7b4f6548",
        "statement":"Never have I ever hung upside down from monkey bars.",
        "category":"harmless"
      },
      {
        "ID":"69737494-a9cd-49ef-b86b-7636ba8345e2",
        "statement":"Never have I ever had the feeling of being selfish.",
        "category":"harmless"
      },
      {
        "ID":"a14ba026-bcc8-46be-a78c-0687de759105",
        "statement":"Never have I ever lost a family member.",
        "category":"harmless"
      },
      {
        "ID":"c6ee89f0-223f-4b48-8f7c-16dfba6a4d8d",
        "statement":"Never have I ever watched Blue's Clues.",
        "category":"harmless"
      },
      {
        "ID":"665e5732-2d3b-4629-9ef6-96e8c9df3838",
        "statement":"Never have I ever had to vomit from drinking too much.",
        "category":"harmless"
      },
      {
        "ID":"5535c3df-78fc-4efd-96a2-3968b8ffa4f8",
        "statement":"Never have I ever been on stage in front of a crowd.",
        "category":"harmless"
      },
      {
        "ID":"2a323295-f4c9-4436-b498-e6a52d4d4d2c",
        "statement":"Never have I ever got mad at the computer.",
        "category":"harmless"
      },
      {
        "ID":"38e410aa-9d62-403f-aaaf-18fffccb2a85",
        "statement":"Never have I ever appeared in television.",
        "category":"harmless"
      },
      {
        "ID":"c0f06c7e-6976-4304-a62e-c3ef3b504e3f",
        "statement":"Never have I ever stolen money from my parents.",
        "category":"harmless"
      },
      {
        "ID":"3dc0c7e5-7d28-4f0f-ab52-9519b1b63680",
        "statement":"Never have I ever pulled a prank on a teacher.",
        "category":"harmless"
      },
      {
        "ID":"dd4bb2aa-c509-47b8-b143-f52d12f36ac2",
        "statement":"Never have I ever climbed in a tree.",
        "category":"harmless"
      },
      {
        "ID":"9d658236-3a2a-47f4-bb28-edc08e989f29",
        "statement":"Never have I ever drunk the beverage of somebody else.",
        "category":"harmless"
      },
      {
        "ID":"03ea81cb-8a88-4c09-b9de-75eec185deee",
        "statement":"Never have I ever believed my toys had feelings.",
        "category":"harmless"
      },
      {
        "ID":"3b8f5937-a234-4b03-9a7f-d4691f184d19",
        "statement":"Never have I ever spent more than 200$ on one evening.",
        "category":"harmless"
      },
      {
        "ID":"849dae6e-f594-454c-89a3-32757b8399a2",
        "statement":"Never have I ever been a friends with benefits.",
        "category":"harmless"
      },
      {
        "ID":"525e30d0-c38a-4694-94cf-0b0c5af6fa3b",
        "statement":"Never have I ever skipped a movie to make out in the parking lot instead.",
        "category":"harmless"
      },
      {
        "ID":"8270f194-5383-4df4-b080-9a200614e23a",
        "statement":"Never have I ever eaten an insect.",
        "category":"harmless"
      },
      {
        "ID":"2db461c6-a94b-47af-bf37-a4ee86e40236",
        "statement":"Never have I ever returned an item I used or clothing I wore.",
        "category":"harmless"
      },
      {
        "ID":"b08729f9-6a7c-461f-ad99-df4239489b5f",
        "statement":"Never have I ever done something I'm still embarrassed of.",
        "category":"harmless"
      },
      {
        "ID":"58c46850-3bac-4d1c-ab88-f89e56de16a4",
        "statement":"Never have I ever tried a restaurant's food challenge.",
        "category":"harmless"
      },
      {
        "ID":"7a6f3ec5-8fd3-4c8f-b517-0507ae0fad81",
        "statement":"Never have I ever talked to my stuffed animal.",
        "category":"harmless"
      },
      {
        "ID":"a42651e3-a20d-43b6-add8-c353ef026429",
        "statement":"Never have I ever drunk coffee.",
        "category":"harmless"
      },
      {
        "ID":"0d58507d-a72a-497e-a350-24a3e9f04ba5",
        "statement":"Never have I ever missed a high five.",
        "category":"harmless"
      },
      {
        "ID":"be9a1e7e-2b84-4650-b542-32a1fafeb52f",
        "statement":"Never have I ever performed in a talent show.",
        "category":"harmless"
      },
      {
        "ID":"279bf241-d475-40ad-badd-b7b906352983",
        "statement":"Never have I ever wanted to be an astronaut.",
        "category":"harmless"
      },
      {
        "ID":"00801adf-0ad4-4118-a74f-8e6c64a2a5fc",
        "statement":"Never have I ever lied to my parents.",
        "category":"harmless"
      },
      {
        "ID":"2f4da5f2-8a52-43c2-8a26-9a5f984a1080",
        "statement":"Never have I ever used a toothbrush that didn't belong to me.",
        "category":"harmless"
      },
      {
        "ID":"cfc769df-5934-42d0-a343-52dba2733cb4",
        "statement":"Never have I ever stayed up all night.",
        "category":"harmless"
      },
      {
        "ID":"657e6d9c-a5a0-4c66-a8a3-bc44cbd0ca34",
        "statement":"Never have I ever had a jello shot.",
        "category":"harmless"
      },
      {
        "ID":"8486c2f2-d719-42da-b1f6-46166f078697",
        "statement":"Never have I ever said a toast.",
        "category":"harmless"
      },
      {
        "ID":"2d97f201-190e-442e-91ea-8e5d5597179b",
        "statement":"Never have I ever eaten something that was days over its date of expiry.",
        "category":"harmless"
      },
      {
        "ID":"9d983ac7-3d83-4cc4-aedf-47f3470eea74",
        "statement":"Never have I ever had breakfast in bed.",
        "category":"harmless"
      },
      {
        "ID":"9670ba61-61d5-489e-af8b-da25bf45eb3d",
        "statement":"Never have I ever made vodka gummy bears.",
        "category":"harmless"
      },
      {
        "ID":"faadf8ab-fa1d-4b3d-9cf1-a06362cfc524",
        "statement":"Never have I ever drank before I turned 21.",
        "category":"harmless"
      },
      {
        "ID":"e8028397-8f2b-4219-b58a-3a561dd688e3",
        "statement":"Never have I ever been jealous when I heard that a celebrity is in a relationship.",
        "category":"harmless"
      },
      {
        "ID":"4fcaab2e-190c-4863-b06c-560ff9bb2200",
        "statement":"Never have I ever sang on a stage.",
        "category":"harmless"
      },
      {
        "ID":"ccc46359-343d-4507-ac56-b708d998c3bd",
        "statement":"Never have I ever owned 7 pets (including fish).",
        "category":"harmless"
      },
      {
        "ID":"06cc8c04-e20a-4b15-b0fa-6a322b40da38",
        "statement":"Never have I ever looked for a better job.",
        "category":"harmless"
      },
      {
        "ID":"4823ef80-cf1a-401a-a0ae-337c6c816cfb",
        "statement":"Never have I ever worn handcuffs.",
        "category":"harmless"
      },
      {
        "ID":"fc807f70-6994-4b39-8b75-8ef72ee60956",
        "statement":"Never have I ever cried at a party.",
        "category":"harmless"
      },
      {
        "ID":"77b5f620-a0a6-4d08-ae6c-91d423c23afb",
        "statement":"Never have I ever made a weird face on a class photo.",
        "category":"harmless"
      },
      {
        "ID":"780ed944-ca14-4b48-857d-f619f3c50ead",
        "statement":"Never have I ever cheated in an exam.",
        "category":"harmless"
      },
      {
        "ID":"2b77cf03-5a8a-41a2-a9cd-e4e4ada7fc89",
        "statement":"Never have I ever spoken a foreign language.",
        "category":"harmless"
      },
      {
        "ID":"d79d08e8-d70e-4fe3-8dca-94ce625a0569",
        "statement":"Never have I ever missed my plane.",
        "category":"harmless"
      },
      {
        "ID":"84913413-3baf-44db-a92c-93095c3365b0",
        "statement":"Never have I ever tasted dog or cat food.",
        "category":"harmless"
      },
      {
        "ID":"c996c867-d771-4a7d-958d-a359720cfb75",
        "statement":"Never have I ever slept during class.",
        "category":"harmless"
      },
      {
        "ID":"1bdd33e2-c185-4770-b598-112e0636f028",
        "statement":"Never have I ever fallen asleep in class.",
        "category":"harmless"
      },
      {
        "ID":"f61f65a2-1fe2-4aeb-b307-b73cb9b0b305",
        "statement":"Never have I ever chewed with my mouth open.",
        "category":"harmless"
      },
      {
        "ID": "2056f3d1-b529-41b7-9d33-f7e375ca0e42",
        "statement": "Never have I ever worn a uniform to school.",
        "category": "harmless"
      },
      {
        "ID": "e81b3908-6270-4058-af12-71bdbcc53a63",
        "statement": "Never have I ever accidentally grabbed someone else's popcorn in a cinema.",
        "category": "harmless"
      }
    ]
  ''';
}
