#ifndef BOOST_SERIALIZATION_LIST_HPP
#define BOOST_SERIALIZATION_LIST_HPP

// MS compatible compilers support #pragma once
#if defined(_MSC_VER) && (_MSC_VER >= 1020)
# pragma once
#endif

/////////1/////////2/////////3/////////4/////////5/////////6/////////7/////////8
// list.hpp: serialization for stl list templates

// (C) Copyright 2002 Robert Ramey - http://www.rrsd.com . 
// Use, modification and distribution is subject to the Boost Software
// License, Version 1.0. (See accompanying file LICENSE_1_0.txt or copy at
// http://www.lslboost.org/LICENSE_1_0.txt)

//  See http://www.lslboost.org for updates, documentation, and revision history.

#include <list>

#include <lslboost/config.hpp>

#include <lslboost/serialization/collections_save_imp.hpp>
#include <lslboost/serialization/collections_load_imp.hpp>
#include <lslboost/serialization/split_free.hpp>

namespace lslboost { 
namespace serialization {

template<class Archive, class U, class Allocator>
inline void save(
    Archive & ar,
    const std::list<U, Allocator> &t,
    const unsigned int /* file_version */
){
    lslboost::serialization::stl::save_collection<
        Archive, 
        std::list<U, Allocator> 
    >(ar, t);
}

template<class Archive, class U, class Allocator>
inline void load(
    Archive & ar,
    std::list<U, Allocator> &t,
    const unsigned int /* file_version */
){
    lslboost::serialization::stl::load_collection<
        Archive,
        std::list<U, Allocator>,
        lslboost::serialization::stl::archive_input_seq<
            Archive, 
            std::list<U, Allocator> 
        >,
        lslboost::serialization::stl::no_reserve_imp<std::list<U, Allocator> >
    >(ar, t);
}

// split non-intrusive serialization function member into separate
// non intrusive save/load member functions
template<class Archive, class U, class Allocator>
inline void serialize(
    Archive & ar,
    std::list<U, Allocator> & t,
    const unsigned int file_version
){
    lslboost::serialization::split_free(ar, t, file_version);
}

} // serialization
} // namespace lslboost

#include <lslboost/serialization/collection_traits.hpp>

BOOST_SERIALIZATION_COLLECTION_TRAITS(std::list)

#endif // BOOST_SERIALIZATION_LIST_HPP
