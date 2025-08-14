import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/location_sql.dart';

import '../bggApi/bgg_api.dart';
import '../s.dart';
import '../models/bgg_location.dart';

class LocationPicker extends StatefulWidget {
  static final LocationPicker _singleton = LocationPicker._internal();

  factory LocationPicker() {
    return _singleton;
  }

  LocationPicker._internal();

  List<Map> locations = [];
  String selectedLocation = "";

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  Map locationToEdit = {};
  final locationNameController = TextEditingController();
  String? listManageErrorText;
  @override
  void initState() {
    super.initState();

    var defaultLocationRes = getDefaultLocation();
    defaultLocationRes.then((defaultLocationValue) {
      if (defaultLocationValue != null) {
        setState(() {
          LocationPicker().selectedLocation = defaultLocationValue.name;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          if (widget.locations.isEmpty) {
            widget.locations = await getLocalLocations();
          }
          showDialog(
              context: context,
              builder: (buildContext) {
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    content: IntrinsicHeight(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExpansionTile(
                                collapsedIconColor:
                                    Theme.of(context).colorScheme.primary,
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  S.of(context).manageLocations,
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor),
                                ),
                                children: [
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          ElevatedButton(
                                              onPressed: () async {
                                                if (locationToEdit.isNotEmpty) {
                                                  final idToRemove =
                                                      locationToEdit['id'];
                                                  await LocationSQL
                                                      .deleteLocation(Location(
                                                          id: locationToEdit[
                                                              'id'],
                                                          name: locationToEdit[
                                                              'name']));
                                                  if (locationToEdit[
                                                          'isChecked'] ==
                                                      true) {
                                                    widget.selectedLocation =
                                                        "";
                                                  }

                                                  locationToEdit = {};
                                                  widget.locations.removeWhere(
                                                      (loc) =>
                                                          loc['id'] ==
                                                          idToRemove);
                                                  setState(() {});
                                                }
                                              },
                                              child:
                                                  Text(S.of(context).delete)),
                                          Expanded(
                                              child: DropdownButton<Map>(
                                            padding: const EdgeInsets.all(10),
                                            value: locationToEdit.isEmpty
                                                ? null
                                                : locationToEdit,
                                            onChanged: (Map? newLocation) {
                                              if (newLocation != null) {
                                                locationToEdit = newLocation;
                                              }
                                              setState(() {});
                                            },
                                            items: widget.locations
                                                .map<DropdownMenuItem<Map>>(
                                                    (Map location) {
                                              return DropdownMenuItem<Map>(
                                                value: location,
                                                child: Text(location['name']
                                                    .toString()),
                                              );
                                            }).toList(),
                                          )),
                                        ],
                                      ),
                                      Row(children: [
                                        ElevatedButton(
                                            onPressed: () async {
                                              if (locationNameController.text ==
                                                  "") {
                                                listManageErrorText = S
                                                    .of(context)
                                                    .locationNameCantBeEmpty;
                                                setState(() {});
                                                return;
                                              }
                                              listManageErrorText = null;
                                              int newId =
                                                  await LocationSQL.getMaxID() +
                                                      1;
                                              var newLocation = Location(
                                                  id: newId,
                                                  name: locationNameController
                                                      .text);
                                              await LocationSQL.addLocation(
                                                  newLocation);
                                              locationNameController.text = "";
                                              widget.locations.add({
                                                "isChecked": 0,
                                                "name": newLocation.name,
                                                "id": newLocation.id,
                                                "isDefault": 0
                                              });
                                              setState(() {});
                                            },
                                            child: Text(S.of(context).create)),
                                        Expanded(
                                            child: TextField(
                                                controller:
                                                    locationNameController,
                                                decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .fromLTRB(
                                                            10, 0, 0, 0),
                                                    labelText: S
                                                        .of(context)
                                                        .locationName,
                                                    errorText:
                                                        listManageErrorText,
                                                    hintText: S
                                                        .of(context)
                                                        .enterTheName))),
                                      ])
                                    ],
                                  )
                                ]),
                            Column(
                                children: widget.locations.map((location) {
                              return Column(children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                    for (var checkedLocation
                                        in widget.locations) {
                                      checkedLocation['isChecked'] = false;
                                    }
                                    location['isChecked'] = true;
                                    widget.selectedLocation = location['name'];
                                  },
                                  style: ButtonStyle(
                                    shadowColor: WidgetStateProperty.all(
                                        Colors.transparent),
                                    shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                        const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                            side: BorderSide.none)),
                                  ),
                                  child: Row(children: [
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(
                                      textAlign: TextAlign.left,
                                      location['name'],
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                  ]),
                                ),
                                const Divider(),
                              ]);
                            }).toList())
                          ],
                        ),
                      ),
                    ),
                  );
                });
              }).then((value) {
            setState(() {});
          });
        },
        style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: Text(widget.selectedLocation.isEmpty
            ? S.of(context).selectLocation
            : widget.selectedLocation),
        icon: const Icon(Icons.home));
  }
}

class LocationPickerSimple extends StatefulWidget {
  LocationPickerSimple({required this.location, super.key});

  List<Map> locations = [];
  String location;

  @override
  State<LocationPickerSimple> createState() => _LocationPickerSimpleState();
}

class _LocationPickerSimpleState extends State<LocationPickerSimple> {
  Map locationToEdit = {};
  final locationNameController = TextEditingController();
  String? listManageErrorText;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        onPressed: () async {
          if (widget.locations.isEmpty) {
            widget.locations = await getLocalLocations();
          }
          showDialog(
              context: context,
              builder: (buildContext) {
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                      content: IntrinsicHeight(
                          child: SingleChildScrollView(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                        ExpansionTile(
                            collapsedIconColor:
                                Theme.of(context).colorScheme.primary,
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              S.of(context).manageLocations,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                            children: [
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      ElevatedButton(
                                          onPressed: () async {
                                            if (locationToEdit.isNotEmpty) {
                                              final idToRemove =
                                                  locationToEdit['id'];
                                              await LocationSQL.deleteLocation(
                                                  Location(
                                                      id: locationToEdit['id'],
                                                      name: locationToEdit[
                                                          'name']));

                                              locationToEdit = {};
                                              widget.locations.removeWhere(
                                                  (loc) =>
                                                      loc['id'] == idToRemove);
                                              setState(() {});
                                            }
                                          },
                                          child: Text(S.of(context).delete)),
                                      Expanded(
                                          child: DropdownButton<Map>(
                                        padding: const EdgeInsets.all(10),
                                        value: locationToEdit.isEmpty
                                            ? null
                                            : locationToEdit,
                                        onChanged: (Map? newLocation) {
                                          if (newLocation != null) {
                                            locationToEdit = newLocation;
                                          }
                                          setState(() {});
                                        },
                                        items: widget.locations
                                            .map<DropdownMenuItem<Map>>(
                                                (Map location) {
                                          return DropdownMenuItem<Map>(
                                            value: location,
                                            child: Text(
                                                location['name'].toString()),
                                          );
                                        }).toList(),
                                      )),
                                    ],
                                  ),
                                  Row(children: [
                                    ElevatedButton(
                                        onPressed: () async {
                                          if (locationNameController.text ==
                                              "") {
                                            listManageErrorText = S
                                                .of(context)
                                                .locationNameCantBeEmpty;
                                            setState(() {});
                                            return;
                                          }
                                          listManageErrorText = null;
                                          int newId =
                                              await LocationSQL.getMaxID() + 1;
                                          var newLocation = Location(
                                              id: newId,
                                              name:
                                                  locationNameController.text);
                                          await LocationSQL.addLocation(
                                              newLocation);
                                          locationNameController.text = "";
                                          widget.locations.add({
                                            "isChecked": 0,
                                            "name": newLocation.name,
                                            "id": newLocation.id,
                                            "isDefault": 0
                                          });
                                          setState(() {});
                                        },
                                        child: Text(S.of(context).create)),
                                    Expanded(
                                        child: TextField(
                                            controller: locationNameController,
                                            decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 0, 0, 0),
                                                labelText:
                                                    S.of(context).locationName,
                                                errorText: listManageErrorText,
                                                hintText: S
                                                    .of(context)
                                                    .enterTheName))),
                                  ])
                                ],
                              )
                            ]),
                        Column(
                            children: widget.locations.map((location) {
                          return Column(children: [
                            const Divider(),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                                for (var checkedLocation in widget.locations) {
                                  checkedLocation['isChecked'] = false;
                                }
                                location['isChecked'] = true;
                                widget.location = location['name'];
                              },
                              style: ButtonStyle(
                                shadowColor:
                                    WidgetStateProperty.all(Colors.transparent),
                                shape: WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
                                    const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                        side: BorderSide.none)),
                              ),
                              child: Row(children: [
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                  textAlign: TextAlign.left,
                                  location['name'],
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ]),
                            )
                          ]);
                        }).toList())
                      ]))));
                });
              }).then((value) {
            setState(() {});
          });
        },
        style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black12)))),
        label: Text(widget.location.isEmpty
            ? S.of(context).selectLocation
            : widget.location),
        icon: const Icon(Icons.home));
  }
}
