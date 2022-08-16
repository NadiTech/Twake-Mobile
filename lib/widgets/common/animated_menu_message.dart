import 'dart:ui';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twake/blocs/message_animation_cubit/message_animation_cubit.dart';
import 'package:twake/blocs/messages_cubit/messages_cubit.dart';
import 'package:twake/models/message/message.dart';
import 'package:twake/pages/chat/message_tile.dart';
import 'package:twake/widgets/message/emoji_set.dart';

class MenuMessageDropDown<T extends BaseMessagesCubit> extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final Size? messagesListSize;
  final Offset? messageListPosition;
  final int clickedItem;
  final bool isReverse;

  /// widget which is below message
  final Widget lowerWidget;

  /// in order to long press animation work, it require the height of widget when it's not even build
  final double lowerWidgetHeight;

  final Message message;

  const MenuMessageDropDown({
    key,
    required this.message,
    required this.itemPositionsListener,
    required this.clickedItem,
    required this.lowerWidget,
    required this.lowerWidgetHeight,
    this.messagesListSize,
    this.messageListPosition,
    this.isReverse = true,
  }) : super(key: key);

  @override
  State<MenuMessageDropDown> createState() => _MenuMessageDropDownState<T>();
}

class _MenuMessageDropDownState<T extends BaseMessagesCubit>
    extends State<MenuMessageDropDown> {
  AnimationConfig begin = AnimationConfig();
  late AnimationConfig end;

  int clickedItem = -1;

  bool _emojiVisible = false;

  int numberOfDropDownBar = 0;
  List<dynamic> dropdownFuncs = [];

  @override
  void initState() {
    super.initState();
    clickedItem = widget.clickedItem;

    dropdownFuncs = [
      widget.onReply,
      widget.onCopy,
      widget.onEdit,
      widget.onDelete,
      widget.onPinMessage,
      widget.onUnpinMessage
    ];
    numberOfDropDownBar =
        dropdownFuncs.where((element) => element != null).length;
  }

  void didUpdateWidget(covariant MenuMessageDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    clickedItem = widget.clickedItem;
  }

  @override
  Widget build(BuildContext context) {
    Curve curveAnimation = Curves.fastOutSlowIn;
    Duration durationAnimation = const Duration(milliseconds: 300);

    return ValueListenableBuilder<Iterable<ItemPosition>>(
      valueListenable: widget.itemPositionsListener.itemPositions,
      builder: (context, positions, child) {
        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;

        double? itemLeadingEdge;
        double? itemTrailingEdge;

        if (positions.isEmpty) {
          return Column();
        }

        // if don't find clicked index of item
        Iterable<ItemPosition> clickedPositions =
            positions.where((element) => element.index == clickedItem);
        if (clickedPositions.isEmpty) {
          return Column();
        }
        itemLeadingEdge = clickedPositions.first.itemLeadingEdge;
        itemTrailingEdge = clickedPositions.first.itemTrailingEdge;

        if (widget.isReverse) {
          var tmp = itemLeadingEdge;
          itemLeadingEdge = 1 - itemTrailingEdge;
          itemTrailingEdge = 1 - tmp;
        }

        double emojiHeight = 50;
        double dropMenuHeight = widget.lowerWidgetHeight;
        double messageListHeight = widget.messagesListSize!.height;

        double topLeftListY = 0;
        if  (widget.messageListPosition != null) {
          topLeftListY = widget.messageListPosition!.dy;
        }

        // calculate size of item
        double itemHeight =
            (itemTrailingEdge - itemLeadingEdge) * messageListHeight;
        double middleItemY =
            itemHeight / 2 + topLeftListY + itemLeadingEdge * messageListHeight;
        double itemHeightMax = screenHeight - emojiHeight - dropMenuHeight;
        double totalHeight = itemHeight + emojiHeight + dropMenuHeight;
        double left = 0;
        double topOfComponents =
            itemLeadingEdge * messageListHeight + topLeftListY - emojiHeight;

        double itemScale = 1;
        double itemTranslateY = 0;

        if (itemHeight > itemHeightMax) {
          itemScale = itemHeightMax / itemHeight;
          itemTranslateY = (emojiHeight + itemHeightMax / 2) - middleItemY;
          topOfComponents -= emojiHeight;
        } else {
          if (itemLeadingEdge * messageListHeight + topLeftListY <
              emojiHeight) {
            itemTranslateY = emojiHeight -
                itemLeadingEdge * messageListHeight -
                topLeftListY;
          } else if (itemTrailingEdge * messageListHeight + topLeftListY >
              screenHeight - dropMenuHeight) {
            itemTranslateY = screenHeight -
                dropMenuHeight -
                itemTrailingEdge * messageListHeight -
                topLeftListY;
          }
        }
        // set how animation should end
        end = AnimationConfig(
            blurDegree: 10, translateY: itemTranslateY, scaleFactor: itemScale);
        return IgnorePointer(
            ignoring: false,
            child: TweenAnimationBuilder<AnimationConfig>(
              duration: durationAnimation,
              tween: Tween<AnimationConfig>(
                begin: begin,
                end: end,
              ),
              curve: curveAnimation,
              builder: (context, animationConfig, __) {
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.find<MessageAnimationCubit>().endAnimation();
                      },
                      child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: animationConfig.blurDegree,
                            sigmaY: animationConfig.blurDegree,
                          ),
                          child: Container(
                            width: double.maxFinite,
                            height: double.maxFinite,
                            color: Colors.transparent,
                          )),
                    ),
                    Positioned(
                      width: screenWidth,
                      left: left,
                      height: totalHeight,
                      top: topOfComponents,
                      child: GestureDetector(
                        onTap: () =>
                            Get.find<MessageAnimationCubit>().endAnimation(),
                        child: _buildAnimatedMessage(
                          isOwnerMessage: widget.message.isOwnerMessage,
                          curve: curveAnimation,
                          itemTranslateY: itemTranslateY,
                          itemScale: itemScale,
                          duration: durationAnimation,
                          child: Column(
                            children: [
                              Transform.scale(
                                  scale:
                                      animationConfig.scaleDropDown / itemScale,
                                  alignment: widget.message.isOwnerMessage
                                      ? Alignment.bottomRight
                                      : Alignment.bottomLeft,
                                  child: EmojiLine(
                                    onEmojiSelected: onEmojiSelected,
                                    showEmojiBoard: toggleEmojiBoard,
                                  )),
                              MessageTile<T>(message: widget.message),
                              Transform.scale(
                                  alignment: widget.message.isOwnerMessage
                                      ? Alignment.topRight
                                      : Alignment.topLeft,
                                  scale:
                                      animationConfig.scaleDropDown / itemScale,
                                  child: widget.lowerWidget),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_emojiVisible) ...[
                      buildEmojiBoard(),
                    ]
                  ],
                );
              },
            ));
      },
    );
  }

  Widget _buildAnimatedMessage(
      {double itemTranslateY = 0,
      double itemScale = 1,
      required Duration duration,
      required Widget child,
      curve = Curves.linear,
      isOwnerMessage = false}) {
    return TweenAnimationBuilder<AnimationConfig>(
        curve: curve,
        tween: Tween<AnimationConfig>(
            begin: AnimationConfig(),
            end: AnimationConfig(
                scaleFactor: itemScale, translateY: itemTranslateY)),
        duration: duration,
        builder: ((context, value, _) {
          if (value.translateY == 0 && value.scaleFactor == 1) {
            return child;
          }
          return Transform.translate(
            offset: Offset(0, value.translateY),
            child: Transform.scale(
              alignment:
                  isOwnerMessage ? Alignment.centerRight : Alignment.centerLeft,
              scale: value.scaleFactor,
              child: child,
            ),
          );
        }));
  }

  Widget buildEmojiBoard() {
    return Container(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (cat, emoji) {
          toggleEmojiBoard();
          onEmojiSelected(emoji.emoji);
        },
        config: Config(
          columns: 7,
          emojiSizeMax: 32.0,
          verticalSpacing: 0,
          horizontalSpacing: 0,
          initCategory: Category.RECENT,
          bgColor: Theme.of(context).colorScheme.secondaryContainer,
          indicatorColor: Theme.of(context).colorScheme.surface,
          iconColor: Theme.of(context).colorScheme.secondary,
          iconColorSelected: Theme.of(context).colorScheme.surface,
          progressIndicatorColor: Theme.of(context).colorScheme.surface,
          showRecentsTab: true,
          recentsLimit: 28,
          noRecentsText: AppLocalizations.of(context)!.noRecents,
          noRecentsStyle:
              Theme.of(context).textTheme.headline3!.copyWith(fontSize: 20),
          categoryIcons: const CategoryIcons(),
          buttonMode: ButtonMode.MATERIAL,
        ),
      ),
    );
  }

  onEmojiSelected(String emojiCode, {bool popOut = false}) async {
    if (widget.message.inThread) {
      await Get.find<ThreadMessagesCubit>()
          .react(message: widget.message, reaction: emojiCode);
    } else {
      await Get.find<ChannelMessagesCubit>()
          .react(message: widget.message, reaction: emojiCode);
    }
    Future.delayed(
      Duration(milliseconds: 50),
      FocusManager.instance.primaryFocus?.unfocus,
    );

    Get.find<MessageAnimationCubit>().endAnimation();
  }

  void toggleEmojiBoard() async {
    setState(() {
      _emojiVisible = !_emojiVisible;
    });
  }
}

class DropDownButton extends StatelessWidget {
  final bool isTop;
  final bool isBottom;
  final String text;
  final IconData icon;
  final Color color;
  final Function() onClick;

  const DropDownButton({
    this.isBottom = false,
    this.isTop = false,
    required this.onClick,
    required this.text,
    required this.icon,
    this.color = Colors.white,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: () => onClick(),
        child: Container(
          decoration: BoxDecoration(
              color: color,
              borderRadius: isTop
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0))
                  : (isBottom
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0))
                      : null)),
          width: 200,
          height: 40,
          padding: const EdgeInsets.all(5.0),
          child: Row(children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [Text(text)],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Icon(icon)],
            ),
          ]),
        ),
      ),
      Container(color: isBottom ? null : Colors.black, height: 1, width: 200),
    ]);
  }
}

class AnimationConfig extends Object {
  double blurDegree;
  double translateY;
  double scaleFactor;
  double scaleDropDown;

  AnimationConfig(
      {this.blurDegree = 10,
      this.translateY = 0,
      this.scaleFactor = 1,
      this.scaleDropDown = 1});

  AnimationConfig operator +(Object other) {
    if (other is AnimationConfig) {
      return AnimationConfig(
          blurDegree: blurDegree + other.blurDegree,
          scaleFactor: scaleFactor + other.scaleFactor,
          translateY: translateY + other.translateY,
          scaleDropDown: scaleDropDown + other.scaleDropDown);
    } else if (other is double || other is int) {
      other = other as double;
      return AnimationConfig(
          blurDegree: blurDegree + other,
          scaleFactor: scaleFactor + other,
          translateY: translateY + other,
          scaleDropDown: scaleDropDown + other);
    }
    throw UnsupportedError("unsupport operation");
  }

  AnimationConfig operator -(Object other) {
    if (other is AnimationConfig) {
      return AnimationConfig(
          blurDegree: blurDegree - other.blurDegree,
          scaleFactor: scaleFactor - other.scaleFactor,
          translateY: translateY - other.translateY,
          scaleDropDown: scaleDropDown - other.scaleDropDown);
    } else if (other is double || other is int) {
      other = other as double;
      return AnimationConfig(
          blurDegree: blurDegree - other,
          scaleFactor: scaleFactor - other,
          translateY: translateY - other,
          scaleDropDown: scaleDropDown - other);
    }
    throw UnsupportedError("unsupport operation");
  }

  AnimationConfig operator *(Object other) {
    if (other is AnimationConfig) {
      return AnimationConfig(
          blurDegree: blurDegree * other.blurDegree,
          scaleFactor: scaleFactor * other.scaleFactor,
          translateY: translateY * other.translateY,
          scaleDropDown: scaleDropDown * other.scaleDropDown);
    } else if (other is double || other is int) {
      other = other as double;
      return AnimationConfig(
          blurDegree: blurDegree * other,
          scaleFactor: scaleFactor * other,
          translateY: translateY * other,
          scaleDropDown: scaleDropDown * other);
    }
    throw UnsupportedError("unsupport operation");
  }

  AnimationConfig operator /(Object other) {
    if (other is AnimationConfig) {
      return AnimationConfig(
          blurDegree: blurDegree / other.blurDegree,
          scaleFactor: scaleFactor / other.scaleFactor,
          translateY: translateY / other.translateY,
          scaleDropDown: scaleDropDown / other.scaleDropDown);
    } else if (other is double || other is int) {
      other = other as double;
      return AnimationConfig(
          blurDegree: blurDegree / other,
          scaleFactor: scaleFactor / other,
          translateY: translateY / other,
          scaleDropDown: scaleDropDown / other);
    }
    throw UnsupportedError("unsupport operation");
  }

  @override
  bool operator ==(Object other) {
    if (other is AnimationConfig) {
      return blurDegree == other.blurDegree &&
          scaleFactor == other.scaleFactor &&
          translateY == other.translateY &&
          scaleDropDown == other.scaleDropDown;
    }
    throw UnsupportedError("unsupport operation");
  }

  @override
  int get hashCode =>
      blurDegree.hashCode +
      scaleFactor.hashCode +
      translateY.hashCode +
      scaleDropDown.hashCode;
}
