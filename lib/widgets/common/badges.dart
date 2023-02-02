import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:twake/blocs/badges_cubit/badges_cubit.dart';
import 'package:twake/blocs/badges_cubit/badges_state.dart';
import 'package:twake/models/badge/badge.dart' as twake;

class BadgesCount extends StatelessWidget {
  final twake.BadgeType type;
  final String id;
  final bool isInDirects;
  final bool isTitleVisible;
  BadgesCount({
    ValueKey? key,
    required this.type,
    required this.id,
    required this.isTitleVisible,
    this.isInDirects = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        isTitleVisible
            ? isInDirects
                ? Text(AppLocalizations.of(context)!.chats)
                : Text(AppLocalizations.of(context)!.channels)
            : SizedBox.shrink(),
        SizedBox(
          width: 5,
          height: 5,
        ),
        BlocBuilder<BadgesCubit, BadgesState>(
          bloc: Get.find<BadgesCubit>(),
          builder: (ctx, state) {
            if (state is BadgesLoadSuccess) {
              final counter = isInDirects
                  ? Get.find<BadgesCubit>().unreadInDirects
                  : state.badges
                      .firstWhere(
                        (b) => b.matches(type: type, id: id),
                        orElse: () => twake.Badge(type: twake.BadgeType.none, id: ''),
                      )
                      .count;

              return counter > 0
                  ? Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF004DFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 3,
                          ),
                          counter < 999
                              ? Text(
                                  '$counter',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  ' 999 ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          SizedBox(
                            width: 3,
                          ),
                        ],
                      ),
                    )
                  : Container();
            } else
              return Container();
          },
        ),
      ],
    );
  }
}
