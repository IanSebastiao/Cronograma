// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database_helper.dart';

class FeriadosDialog extends StatefulWidget {
  final Map<DateTime, String> feriadosNacionais;
  final Map<DateTime, String> feriadosMunicipais;
  final Function() onFeriadoAdded;

  const FeriadosDialog({
    super.key,
    required this.feriadosNacionais,
    required this.feriadosMunicipais,
    required this.onFeriadoAdded,
  });

  @override
  _FeriadosDialogState createState() => _FeriadosDialogState();
}

class _FeriadosDialogState extends State<FeriadosDialog> {
  late Map<DateTime, String> _feriadosMunicipais;

  @override
  void initState() {
    super.initState();
    _feriadosMunicipais = Map.from(widget.feriadosMunicipais);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Feriados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feriados Nacionais
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text(
                              'Feriados Nacionais',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            Expanded(
                              child: ListView(
                                children: widget.feriadosNacionais.entries
                                    .map((e) => ListTile(
                                          leading: const Icon(Icons.flag, color: Colors.green),
                                          title: Text(e.value),
                                          subtitle: Text(
                                            DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(e.key),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Feriados Municipais
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text(
                              'Feriados Municipais',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            Expanded(
                              child: _feriadosMunicipais.isEmpty
                                  ? const Center(
                                      child: Text('Nenhum feriado municipal cadastrado'),
                                    )
                                  : ListView(
                                      children: _feriadosMunicipais.entries
                                          .map((e) => ListTile(
                                                leading: const Icon(Icons.location_city, color: Colors.blue),
                                                title: Text(e.value),
                                                subtitle: Text(
                                                  DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(e.key),
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () async {
                                                    await _removerFeriadoMunicipal(e.key, e.value);
                                                  },
                                                ),
                                              ))
                                          .toList(),
                                    ),
                            ),
                            const Divider(),
                            ElevatedButton(
                              onPressed: _showAddFeriadoDialog,
                              child: const Text('Adicionar Feriado Municipal'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removerFeriadoMunicipal(DateTime data, String nome) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'FeriadosMunicipais',
        where: 'data = ? AND nome = ?',
        whereArgs: [DateFormat('yyyy-MM-dd').format(data), nome],
      );

      setState(() {
        _feriadosMunicipais.remove(data);
      });

      widget.onFeriadoAdded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover feriado: $e')),
      );
    }
  }

  void _showAddFeriadoDialog() {
    final feriadoMunicipalController = TextEditingController();
    DateTime? selectedDateFeriado;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Adicionar Feriado Municipal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: feriadoMunicipalController,
                decoration: const InputDecoration(labelText: 'Nome do Feriado'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setStateDialog(() {
                      selectedDateFeriado = date;
                    });
                  }
                },
                child: Text(
                  selectedDateFeriado == null
                      ? 'Selecionar Data'
                      : 'Data: ${DateFormat('dd/MM/yyyy').format(selectedDateFeriado!)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDateFeriado == null || feriadoMunicipalController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha a data e o nome do feriado')),
                  );
                  return;
                }

                try {
                  final db = await DatabaseHelper.instance.database;
                  await db.insert('FeriadosMunicipais', {
                    'data': DateFormat('yyyy-MM-dd').format(selectedDateFeriado!),
                    'nome': feriadoMunicipalController.text,
                  });

                  setState(() {
                    _feriadosMunicipais[selectedDateFeriado!] = feriadoMunicipalController.text;
                  });

                  widget.onFeriadoAdded();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao adicionar feriado: $e')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
