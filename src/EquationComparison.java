// AUTO GENERATED CODE - DO NOT MODIFY
@SuppressWarnings("DuplicateBranchesInSwitch")
public final class EquationComparison {
  static PartialOrder compare(KnuthBendixOrder order, Equation a, Equation b) {
    switch (order.compare(a.left, a.right)) {
      case EQ -> {
        switch (order.compare(a.left, b.left)) {
          case EQ -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
            }
          }
          case GT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                return PartialOrder.GT;
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case LT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(b.left, b.right)) {
                  case EQ -> {
                    return PartialOrder.LT;
                  }
                  case GT -> {
                    return PartialOrder.LT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          case UNORDERED -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
            }
          }
        }
      }
      case GT -> {
        switch (order.compare(a.left, b.left)) {
          case EQ -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(b.left, b.right)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.EQ;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.EQ;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.EQ;
                  }
                  case LT -> {
                    return PartialOrder.EQ;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.EQ;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.EQ;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
            }
          }
          case GT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                return PartialOrder.GT;
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          case LT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(b.left, b.right)) {
                  case EQ -> {
                    return PartialOrder.LT;
                  }
                  case GT -> {
                    return PartialOrder.LT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          case UNORDERED -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
            }
          }
        }
      }
      case LT -> {
        switch (order.compare(a.left, b.left)) {
          case EQ -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(b.left, b.right)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.EQ;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.GT;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.EQ;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.EQ;
                  }
                  case LT -> {
                    return PartialOrder.EQ;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.EQ;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.EQ;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.left)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.left)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case GT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                return PartialOrder.GT;
              }
              case LT -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.left)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.left)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case LT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case UNORDERED -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      case UNORDERED -> {
        switch (order.compare(a.left, b.left)) {
          case EQ -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.EQ;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case GT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                return PartialOrder.GT;
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case LT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case UNORDERED -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.EQ;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
            }
          }
        }
      }
    }
    throw new IllegalStateException();
  }

  static PartialOrder compareNP(KnuthBendixOrder order, Equation a, Equation b) {
    switch (order.compare(a.left, a.right)) {
      case EQ -> {
        switch (order.compare(a.left, b.left)) {
          case EQ -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case GT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                return PartialOrder.GT;
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case LT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(b.left, b.right)) {
                  case EQ -> {
                    return PartialOrder.LT;
                  }
                  case GT -> {
                    return PartialOrder.LT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          case UNORDERED -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
            }
          }
        }
      }
      case GT -> {
        switch (order.compare(a.left, b.left)) {
          case EQ -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(b.left, b.right)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case GT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                return PartialOrder.GT;
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          case LT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(b.left, b.right)) {
                  case EQ -> {
                    return PartialOrder.LT;
                  }
                  case GT -> {
                    return PartialOrder.LT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.LT;
                      }
                      case GT -> {
                        return PartialOrder.LT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          case UNORDERED -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
            }
          }
        }
      }
      case LT -> {
        switch (order.compare(a.left, b.left)) {
          case EQ -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(b.left, b.right)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.left)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.left)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.left)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.left)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case GT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                return PartialOrder.GT;
              }
              case LT -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.left)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.right)) {
                  case EQ -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.left)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.left)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case LT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case UNORDERED -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        switch (order.compare(a.right, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.GT;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.LT;
                          }
                          case GT -> {
                            return PartialOrder.LT;
                          }
                          case LT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        switch (order.compare(b.left, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.UNORDERED;
                          }
                          case LT -> {
                            return PartialOrder.LT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      case UNORDERED -> {
        switch (order.compare(a.left, b.left)) {
          case EQ -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.GT;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case GT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                return PartialOrder.GT;
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case LT -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(b.left, b.right)) {
                      case EQ -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case GT -> {
                        switch (order.compare(a.right, b.right)) {
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        switch (order.compare(a.right, b.right)) {
                          case EQ -> {
                            return PartialOrder.UNORDERED;
                          }
                          case GT -> {
                            return PartialOrder.GT;
                          }
                          case UNORDERED -> {
                            return PartialOrder.UNORDERED;
                          }
                        }
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
            }
          }
          case UNORDERED -> {
            switch (order.compare(a.left, b.right)) {
              case EQ -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.GT;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case GT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    return PartialOrder.GT;
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
              case LT -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.LT;
                  }
                  case UNORDERED -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case LT -> {
                        return PartialOrder.LT;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                }
              }
              case UNORDERED -> {
                switch (order.compare(a.right, b.left)) {
                  case EQ -> {
                    return PartialOrder.UNORDERED;
                  }
                  case GT -> {
                    switch (order.compare(a.right, b.right)) {
                      case EQ -> {
                        return PartialOrder.UNORDERED;
                      }
                      case GT -> {
                        return PartialOrder.GT;
                      }
                      case LT -> {
                        return PartialOrder.UNORDERED;
                      }
                      case UNORDERED -> {
                        return PartialOrder.UNORDERED;
                      }
                    }
                  }
                  case LT -> {
                    return PartialOrder.UNORDERED;
                  }
                  case UNORDERED -> {
                    return PartialOrder.UNORDERED;
                  }
                }
              }
            }
          }
        }
      }
    }
    throw new IllegalStateException();
  }
}
