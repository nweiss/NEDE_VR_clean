/*=============================================================================
    Copyright (c) 2001-2011 Joel de Guzman

    Distributed under the Boost Software License, Version 1.0. (See accompanying
    file LICENSE_1_0.txt or copy at http://www.lslboost.org/LICENSE_1_0.txt)
==============================================================================*/
#if !defined(FUSION_INSERT_10022005_1837)
#define FUSION_INSERT_10022005_1837

#include <lslboost/mpl/insert.hpp>
#include <lslboost/fusion/support/tag_of.hpp>
#include <lslboost/fusion/algorithm/transformation/insert.hpp>
#include <lslboost/fusion/sequence/convert.hpp>

namespace lslboost { namespace mpl
{
    template <typename Tag>
    struct insert_impl;

    template <>
    struct insert_impl<fusion::fusion_sequence_tag>
    {
        template <typename Sequence, typename Pos, typename T>
        struct apply
        {
            typedef typename
                fusion::result_of::insert<Sequence, Pos, T>::type
            result;

            typedef typename
                fusion::result_of::convert<
                    typename fusion::detail::tag_of<Sequence>::type, result>::type
            type;
        };
    };
}}

#endif

